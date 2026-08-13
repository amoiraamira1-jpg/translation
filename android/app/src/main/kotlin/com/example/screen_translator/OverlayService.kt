package com.example.screen_translator

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Rect
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.DisplayMetrics
import android.view.*
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import androidx.core.app.NotificationCompat

/**
 * Foreground service that owns:
 *  1) the small draggable floating icon shown over every other app,
 *  2) a one-shot screen capture (MediaProjection) triggered by tapping it,
 *  3) OCR (OcrEngine) + on-device translation (TranslateEngine) of what was
 *     captured, and
 *  4) a transparent overlay that draws the translated text back on top of
 *     the original text.
 *
 * All behaviour toggles (icon size/opacity, auto-move-to-edge, region mode,
 * hide close/settings icon, one-touch-close, vertical text, upcase, center
 * align) are read live from [Prefs], which the Flutter settings screens
 * write to.
 */
class OverlayService : Service() {

    private lateinit var windowManager: WindowManager
    private var iconView: ImageView? = null
    private var iconParams: WindowManager.LayoutParams? = null

    private var resultOverlay: FrameLayout? = null
    private var regionSelectView: RegionSelectView? = null

    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null

    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingRegionAnchor: Pair<Int, Int>? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                if (mediaProjection != null) {
                    startForeground(NOTIF_ID, buildNotification())
                    showFloatingIcon()
                } else {
                    startActivity(Intent(this, ScreenCaptureActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    })
                    stopSelf()
                }
            }
            ACTION_STOP -> stopSelf()
            ACTION_CAPTURE_GRANTED -> {
                startForeground(NOTIF_ID, buildNotification())
                val code = intent.getIntExtra(EXTRA_RESULT_CODE, Activity.RESULT_CANCELED)
                val data = intent.getParcelableExtra<Intent>(EXTRA_RESULT_DATA)
                if (code == Activity.RESULT_OK && data != null) {
                    attachProjection(code, data)
                    showFloatingIcon()
                    performCapture(pendingRegionAnchor?.let { lastRegionRect } )
                } else {
                    stopSelf()
                }
            }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        removeResultOverlay()
        iconView?.let { runCatching { windowManager.removeView(it) } }
        virtualDisplay?.release()
        imageReader?.close()
        mediaProjection?.stop()
        super.onDestroy()
    }

    // ---------------------------------------------------------------- icon

    private fun showFloatingIcon() {
        if (iconView != null) return

        val sizePx = dp(Prefs.iconSize(this))
        val icon = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_menu_camera) // swap for a custom target/crosshair asset
            alpha = (Prefs.iconTransparency(this@OverlayService) / 100f).coerceIn(0.15f, 1f)
            layoutParams = FrameLayout.LayoutParams(sizePx, sizePx)
        }

        val overlayType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE

        val params = WindowManager.LayoutParams(
            sizePx, sizePx, overlayType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 0
            y = screenSize().y / 3
        }

        attachDragAndTapBehaviour(icon, params)
        windowManager.addView(icon, params)
        iconView = icon
        iconParams = params
        scheduleAutoMove()
    }

    private fun attachDragAndTapBehaviour(icon: ImageView, params: WindowManager.LayoutParams) {
        var downX = 0f; var downY = 0f
        var startX = 0; var startY = 0
        var moved = false
        var longPressTriggered = false
        val longPressRunnable = Runnable {
            if (moved && Prefs.autoActivateRegionMode(this)) {
                longPressTriggered = true
                enterRegionSelectMode(params.x, params.y)
            }
        }

        icon.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    cancelAutoMove()
                    icon.alpha = (Prefs.iconTransparency(this) / 100f).coerceIn(0.15f, 1f)
                    downX = event.rawX; downY = event.rawY
                    startX = params.x; startY = params.y
                    moved = false; longPressTriggered = false
                    mainHandler.postDelayed(longPressRunnable, 550)
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = (event.rawX - downX).toInt()
                    val dy = (event.rawY - downY).toInt()
                    if (kotlin.math.abs(dx) > 12 || kotlin.math.abs(dy) > 12) moved = true
                    if (!longPressTriggered) {
                        params.x = startX + dx
                        params.y = startY + dy
                        runCatching { windowManager.updateViewLayout(icon, params) }
                    } else {
                        regionSelectView?.updateCurrent(event.rawX.toInt(), event.rawY.toInt())
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    mainHandler.removeCallbacks(longPressRunnable)
                    if (longPressTriggered) {
                        regionSelectView?.finishSelection()
                    } else if (!moved) {
                        // plain tap -> capture the whole screen
                        requestCapture(region = null)
                    } else {
                        scheduleAutoMove()
                    }
                    true
                }
                else -> false
            }
        }
    }

    private fun scheduleAutoMove() {
        if (!Prefs.autoMoveToEdge(this)) return
        mainHandler.postDelayed(autoMoveRunnable, 2000)
    }

    private fun cancelAutoMove() = mainHandler.removeCallbacks(autoMoveRunnable)

    private val autoMoveRunnable = Runnable {
        val icon = iconView ?: return@Runnable
        val params = iconParams ?: return@Runnable
        val screenW = screenSize().x
        val targetX = if (params.x + icon.width / 2 < screenW / 2) 0 else screenW - icon.width
        params.x = targetX
        runCatching { windowManager.updateViewLayout(icon, params) }
        icon.animate().alpha(0.35f).setDuration(300).start()
    }

    // -------------------------------------------------------- region mode

    private var lastRegionRect: Rect? = null

    private fun enterRegionSelectMode(anchorX: Int, anchorY: Int) {
        pendingRegionAnchor = anchorX to anchorY
        val view = RegionSelectView(this) { rect ->
            lastRegionRect = rect
            removeRegionSelectView()
            requestCapture(region = rect)
        }
        regionSelectView = view
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        )
        windowManager.addView(view, params)
        view.begin(anchorX, anchorY)
    }

    private fun removeRegionSelectView() {
        regionSelectView?.let { runCatching { windowManager.removeView(it) } }
        regionSelectView = null
    }

    // ---------------------------------------------------------- capture

    private fun requestCapture(region: Rect?) {
        lastRegionRect = region
        if (mediaProjection != null) {
            performCapture(region)
            return
        }
        // Need user consent first; ScreenCaptureActivity forwards the token
        // back to us via ACTION_CAPTURE_GRANTED, and performCapture() runs then.
        startActivity(Intent(this, ScreenCaptureActivity::class.java))
    }

    private fun attachProjection(resultCode: Int, data: Intent) {
        val manager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        mediaProjection = manager.getMediaProjection(resultCode, data)
    }

    private fun performCapture(region: Rect?) {
        val projection = mediaProjection ?: return
        val metrics = DisplayMetrics().also { windowManager.defaultDisplay.getRealMetrics(it) }
        val width = metrics.widthPixels
        val height = metrics.heightPixels
        val density = metrics.densityDpi

        imageReader?.close()
        imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
        virtualDisplay?.release()
        virtualDisplay = projection.createVirtualDisplay(
            "screen-translator-capture", width, height, density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader!!.surface, null, mainHandler
        )

        // Grab exactly one frame, then tear the capture pipeline down again
        // (we keep `mediaProjection` itself so future taps don't re-prompt).
        imageReader!!.setOnImageAvailableListener({ reader ->
            val image: Image? = reader.acquireLatestImage()
            if (image != null) {
                val bitmap = imageToBitmap(image, width, height)
                image.close()
                virtualDisplay?.release(); virtualDisplay = null
                val cropped = region?.let { r -> cropSafely(bitmap, r) } ?: bitmap
                runOcrAndTranslate(cropped)
            }
        }, mainHandler)
    }

    private fun imageToBitmap(image: Image, width: Int, height: Int): Bitmap {
        val plane = image.planes[0]
        val buffer = plane.buffer
        val pixelStride = plane.pixelStride
        val rowStride = plane.rowStride
        val rowPadding = rowStride - pixelStride * width
        val bitmap = Bitmap.createBitmap(
            width + rowPadding / pixelStride, height, Bitmap.Config.ARGB_8888
        )
        bitmap.copyPixelsFromBuffer(buffer)
        return if (bitmap.width == width) bitmap else Bitmap.createBitmap(bitmap, 0, 0, width, height)
    }

    private fun cropSafely(bitmap: Bitmap, rect: Rect): Bitmap {
        val r = Rect(rect).apply {
            left = left.coerceIn(0, bitmap.width - 1)
            top = top.coerceIn(0, bitmap.height - 1)
            right = right.coerceIn(left + 1, bitmap.width)
            bottom = bottom.coerceIn(top + 1, bitmap.height)
        }
        return Bitmap.createBitmap(bitmap, r.left, r.top, r.width(), r.height())
    }

    // ------------------------------------------------------- OCR + translate

    private fun runOcrAndTranslate(bitmap: Bitmap) {
        val source = Prefs.sourceLang(this)
        val target = Prefs.targetLang(this)
        OcrEngine.recognize(bitmap, source, onResult = { blocks ->
            if (blocks.isEmpty()) return@recognize
            showResultOverlay(emptyList()) // clear/prepare container
            blocks.forEach { block ->
                TranslateEngine.translate(block.text, source, target,
                    onResult = { translated -> addTranslatedBubble(block.box, translated) },
                    onError = { /* leave that block untranslated on failure */ })
            }
        }, onError = { })
    }

    // ------------------------------------------------------------ overlay

    private fun showResultOverlay(initial: List<Pair<Rect, String>>) {
        removeResultOverlay()
        val container = FrameLayout(this)
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        )
        if (Prefs.oneTouchClose(this)) {
            container.setOnClickListener { removeResultOverlay() }
            container.isClickable = true
        }
        if (!Prefs.hideCloseIcon(this)) {
            val close = TextView(this).apply {
                text = "\u2715"
                setTextColor(Color.WHITE)
                setBackgroundColor(Color.parseColor("#88000000"))
                setPadding(dp(8), dp(4), dp(8), dp(4))
                layoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT,
                    Gravity.TOP or Gravity.END
                ).apply { topMargin = dp(24); rightMargin = dp(12) }
                setOnClickListener { removeResultOverlay() }
            }
            container.addView(close)
        }
        windowManager.addView(container, params)
        resultOverlay = container
    }

    private fun addTranslatedBubble(box: Rect, text: String) {
        val container = resultOverlay ?: return
        val vertical = Prefs.originalTextVertical(this) &&
            Prefs.sourceLang(this) in setOf("zh", "ja", "ko")
        val label = TextView(this).apply {
            this.text = if (Prefs.upcaseText(this@OverlayService)) text.uppercase() else text
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.parseColor("#CC1A1A1A"))
            gravity = if (Prefs.textAlignCenter(this@OverlayService)) Gravity.CENTER else Gravity.START
            setPadding(dp(4), dp(2), dp(4), dp(2))
            if (vertical) rotation = 90f
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT
            ).apply { leftMargin = box.left; topMargin = box.top }
        }
        container.addView(label)
    }

    private fun removeResultOverlay() {
        resultOverlay?.let { runCatching { windowManager.removeView(it) } }
        resultOverlay = null
    }

    // -------------------------------------------------------------- utils

    private fun screenSize(): android.graphics.Point {
        val p = android.graphics.Point()
        windowManager.defaultDisplay.getRealSize(p)
        return p
    }

    private fun dp(value: Int): Int =
        (value * resources.displayMetrics.density).toInt()

    private fun buildNotification(): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, "Screen Translator", NotificationManager.IMPORTANCE_MIN
            )
            (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(channel)
        }
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Screen Translator is running")
            .setContentText("Tap the floating icon to translate what's on screen")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setOngoing(true)
            .build()
    }

    companion object {
        const val ACTION_START = "com.example.screen_translator.START"
        const val ACTION_STOP = "com.example.screen_translator.STOP"
        const val ACTION_CAPTURE_GRANTED = "com.example.screen_translator.CAPTURE_GRANTED"
        const val EXTRA_RESULT_CODE = "result_code"
        const val EXTRA_RESULT_DATA = "result_data"
        private const val CHANNEL_ID = "overlay_service"
        private const val NOTIF_ID = 1001
    }
}
