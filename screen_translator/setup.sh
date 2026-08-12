#!/data/data/com.termux/files/usr/bin/bash
# Auto-generated: creates the full screen_translator Flutter scaffold.
set -e
PROJECT_DIR="screen_translator"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

cat > "README.md" << '__EOF_SCRIPT__'
# Screen Translator (Flutter + native Android overlay)

A floating screen-translator scaffold like "Tap Translate Screen":
tap a draggable icon over any app → it screenshots, OCRs, and shows the
translation on top of the original text — using only **free, on-device**
engines (Google ML Kit Text Recognition + ML Kit Translate). No paid API,
no API key.

## Architecture (why it's split Flutter + Kotlin)

The floating icon has to keep working while your Flutter UI is closed —
Flutter's engine doesn't run in the background on Android. So:

- **Flutter (`lib/`)** — Home/Translate/Camera/More screens, settings UI,
  exactly the sections in your screenshots (Text Style, Floating Icon,
  Other Settings, More menu). Writes every toggle to `SharedPreferences`.
- **Kotlin (`android/app/.../*.kt`)** — a `Foreground Service`
  (`OverlayService.kt`) that draws the icon, captures the screen via
  `MediaProjection`, runs OCR (`OcrEngine.kt`) and translation
  (`TranslateEngine.kt`), and draws the result overlay. It reads the same
  `SharedPreferences` (`Prefs.kt`) the Flutter side writes to, so a setting
  change applies immediately without restarting the service.
- `MainActivity.kt` is the bridge: a `MethodChannel` lets Flutter ask for
  the overlay permission, start/stop the service, and read/write settings.

## What's implemented vs. what's a starting point

Implemented: floating draggable icon, tap-to-capture full screen,
drag-then-hold to start region selection, `MediaProjection` capture,
on-device OCR with per-block bounding boxes, on-device translation,
overlay rendering with upcase/center-align/vertical-text options, hide
close/settings icon, one-touch-close, auto-move-to-edge-and-dim.

Left as clearly-marked TODOs because they need a real device to iterate on:
fine-tuning the region-selection UX, a custom icon asset, wiring the
Camera and Translate tabs to the same native engines, and a proper
in-app language picker beyond the 6 example pairs.

## Building it in Termux

Termux can build a real Flutter APK — people do this regularly — but the
toolchain is heavy (Flutter SDK + Android SDK + a JDK), so budget real
disk space (3–5 GB) and patience on the first build.

```bash
pkg update && pkg upgrade -y
pkg install -y git wget unzip openjdk-17

# Get a Termux-packaged Flutter SDK (prebuilt for aarch64, avoids
# building Flutter's own engine from source on-device):
curl -s https://raw.githubusercontent.com/Hax4us/flutter_in_termux/master/install.sh | bash -s

# restart Termux, then:
flutter doctor
flutter config --android-sdk $PREFIX/share/android-sdk
```

Then bring this scaffold into a real Flutter project (this repo is
missing the boilerplate files `flutter create` normally generates —
`android/settings.gradle`, `gradle-wrapper`, launcher icons, etc.):

```bash
flutter create screen_translator
cd screen_translator
# copy this repo's lib/, android/app/src/main/AndroidManifest.xml,
# and android/app/src/main/kotlin/ over the generated ones, then:
# paste android/app/build.gradle.snippet's dependencies block into
# the generated android/app/build.gradle
flutter pub get
flutter build apk --release --target-platform android-arm64
```

The APK lands at `build/app/outputs/flutter-apk/app-release.apk`.
Install it with `pkg install android-tools && adb install <path>`, or
just copy the file to your phone and open it.

## Known rough edges to test on-device

- `MediaProjection` requires a one-time user consent dialog per app
  launch (Android security requirement) — `ScreenCaptureActivity.kt`
  handles this, but the first tap after opening the app will always show
  it.
- Some OEMs (Xiaomi, Huawei, Samsung's aggressive battery saver) kill
  background services; the Home screen already shows the same warning
  banner your reference app does.
- `SYSTEM_ALERT_WINDOW` is a "special app access" permission — it can't
  be requested with a normal runtime-permission dialog, which is why
  `requestOverlayPermission()` opens Android's settings screen instead.
__EOF_SCRIPT__

mkdir -p "android/app"
cat > "android/app/build.gradle.snippet" << '__EOF_SCRIPT__'
// -----------------------------------------------------------------------
// Paste the dependencies below into the `dependencies { ... }` block of
// the android/app/build.gradle that `flutter create` generates for you.
// Also make sure (in the same file):
//   android.compileSdk = 34         (Termux aapt2 is happiest at 34)
//   defaultConfig.minSdk = 24       (MediaProjection foreground service
//                                     type requires API 29+ at runtime,
//                                     the app just needs to check at runtime)
//   defaultConfig.targetSdk = 34
//   kotlinOptions.jvmTarget = '17'
// -----------------------------------------------------------------------

dependencies {
    // On-device text recognition (Latin script is bundled; add the others
    // only for the languages you actually need — each is a separate model).
    implementation("com.google.mlkit:text-recognition:16.0.1")
    implementation("com.google.mlkit:text-recognition-chinese:16.0.1")
    implementation("com.google.mlkit:text-recognition-japanese:16.0.1")
    implementation("com.google.mlkit:text-recognition-korean:16.0.1")
    implementation("com.google.mlkit:text-recognition-devanagari:16.0.1")

    // On-device translation — free, no API key, ~30MB per language pair
    // downloaded once.
    implementation("com.google.mlkit:translate:17.0.3")

    implementation("androidx.core:core-ktx:1.13.1")
}
__EOF_SCRIPT__

mkdir -p "android/app/src/main"
cat > "android/app/src/main/AndroidManifest.xml" << '__EOF_SCRIPT__'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Draw the floating icon and translation bubbles over other apps -->
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />

    <!-- Keep the overlay/OCR service alive while the user is in another app -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PROJECTION" />

    <!-- Screen capture (needed to read what's on screen before OCR) -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <!-- Only used the first time to download the on-device ML Kit models -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:label="Screen Translator"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:allowBackup="true"
        android:usesCleartextTraffic="false">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme" />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <!-- Transparent activity used only to request the MediaProjection
             screen-capture consent dialog (Android requires an Activity for this). -->
        <activity
            android:name=".ScreenCaptureActivity"
            android:exported="false"
            android:theme="@android:style/Theme.Translucent.NoTitleBar"
            android:excludeFromRecents="true" />

        <!-- The always-on floating icon + OCR + translation overlay -->
        <service
            android:name=".OverlayService"
            android:exported="false"
            android:foregroundServiceType="mediaProjection" />

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
__EOF_SCRIPT__

mkdir -p "android/app/src/main/kotlin/com/example/screen_translator"
cat > "android/app/src/main/kotlin/com/example/screen_translator/MainActivity.kt" << '__EOF_SCRIPT__'
package com.example.screen_translator

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "screen_translator/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasOverlayPermission" ->
                    result.success(Settings.canDrawOverlays(this))

                "requestOverlayPermission" -> {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:$packageName")
                    )
                    startActivity(intent)
                    result.success(null)
                }

                "startOverlayService" -> {
                    val intent = Intent(this, OverlayService::class.java).apply {
                        action = OverlayService.ACTION_START
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent)
                    else startService(intent)
                    result.success(null)
                }

                "stopOverlayService" -> {
                    startService(Intent(this, OverlayService::class.java).apply {
                        action = OverlayService.ACTION_STOP
                    })
                    result.success(null)
                }

                "getSettings" -> result.success(Prefs.asMap(this))

                "setBool" -> {
                    val key = call.argument<String>("key")!!
                    val value = call.argument<Boolean>("value")!!
                    Prefs.putBool(this, key, value)
                    result.success(null)
                }

                "setInt" -> {
                    val key = call.argument<String>("key")!!
                    val value = call.argument<Int>("value")!!
                    Prefs.putInt(this, key, value)
                    result.success(null)
                }

                "setLanguages" -> {
                    val source = call.argument<String>("source")!!
                    val target = call.argument<String>("target")!!
                    Prefs.setLanguages(this, source, target)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }
}
__EOF_SCRIPT__

mkdir -p "android/app/src/main/kotlin/com/example/screen_translator"
cat > "android/app/src/main/kotlin/com/example/screen_translator/OcrEngine.kt" << '__EOF_SCRIPT__'
package com.example.screen_translator

import android.graphics.Bitmap
import android.graphics.Rect
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.Text
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
import com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
import com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
import com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions

/**
 * Runs Google ML Kit's on-device text recognizer over a captured screen
 * bitmap. This is free and works fully offline (no Cloud Vision key needed).
 *
 * To recognize Chinese / Japanese / Korean you must add the matching
 * `com.google.mlkit:text-recognition-*` dependency in build.gradle (see
 * README) and pick the right recognizer below based on Prefs.sourceLang().
 */
object OcrEngine {

    data class Block(val text: String, val box: Rect)

    private fun recognizerFor(langCode: String) = when (langCode) {
        "zh" -> TextRecognition.getClient(ChineseTextRecognizerOptions.Builder().build())
        "ja" -> TextRecognition.getClient(JapaneseTextRecognizerOptions.Builder().build())
        "ko" -> TextRecognition.getClient(KoreanTextRecognizerOptions.Builder().build())
        "hi" -> TextRecognition.getClient(DevanagariTextRecognizerOptions.Builder().build())
        else -> TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
    }

    /** Returns one [Block] per detected text line, each with its screen bounding box. */
    fun recognize(
        bitmap: Bitmap,
        sourceLangCode: String,
        onResult: (List<Block>) -> Unit,
        onError: (Exception) -> Unit,
    ) {
        val image = InputImage.fromBitmap(bitmap, 0)
        recognizerFor(sourceLangCode).process(image)
            .addOnSuccessListener { visionText: Text ->
                val blocks = mutableListOf<Block>()
                for (block in visionText.textBlocks) {
                    for (line in block.lines) {
                        val box = line.boundingBox ?: continue
                        if (line.text.isNotBlank()) blocks.add(Block(line.text, box))
                    }
                }
                onResult(blocks)
            }
            .addOnFailureListener { onError(it) }
    }
}
__EOF_SCRIPT__

mkdir -p "android/app/src/main/kotlin/com/example/screen_translator"
cat > "android/app/src/main/kotlin/com/example/screen_translator/OverlayService.kt" << '__EOF_SCRIPT__'
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
        startForeground(NOTIF_ID, buildNotification())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> showFloatingIcon()
            ACTION_STOP -> stopSelf()
            ACTION_CAPTURE_GRANTED -> {
                val code = intent.getIntExtra(EXTRA_RESULT_CODE, Activity.RESULT_CANCELED)
                val data = intent.getParcelableExtra<Intent>(EXTRA_RESULT_DATA)
                if (code == Activity.RESULT_OK && data != null) {
                    attachProjection(code, data)
                    performCapture(pendingRegionAnchor?.let { lastRegionRect } )
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
            alpha = 1f - (Prefs.iconTransparency(this@OverlayService) / 100f)
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
                    icon.alpha = 1f - (Prefs.iconTransparency(this) / 100f)
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
        startActivity(Intent(this, ScreenCaptureActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        })
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
__EOF_SCRIPT__

mkdir -p "android/app/src/main/kotlin/com/example/screen_translator"
cat > "android/app/src/main/kotlin/com/example/screen_translator/Prefs.kt" << '__EOF_SCRIPT__'
package com.example.screen_translator

import android.content.Context
import android.content.SharedPreferences

/**
 * Single source of truth for every toggle/slider in the Flutter settings
 * screens. The Flutter side writes to this via MainActivity's MethodChannel;
 * OverlayService (a native background service with no Flutter engine)
 * reads from it directly, so settings changes apply immediately without
 * restarting the floating icon.
 */
object Prefs {
    private const val NAME = "screen_translator_prefs"

    private fun sp(ctx: Context): SharedPreferences =
        ctx.getSharedPreferences(NAME, Context.MODE_PRIVATE)

    // Languages (BCP-47 / ML Kit language codes, e.g. "en", "ar", "ja")
    fun sourceLang(ctx: Context) = sp(ctx).getString("source_lang", "en") ?: "en"
    fun targetLang(ctx: Context) = sp(ctx).getString("target_lang", "ar") ?: "ar"
    fun setLanguages(ctx: Context, source: String, target: String) {
        sp(ctx).edit().putString("source_lang", source).putString("target_lang", target).apply()
    }

    // Floating icon settings (screenshot 3)
    fun iconSize(ctx: Context) = sp(ctx).getInt("icon_size", 35)
    fun iconTransparency(ctx: Context) = sp(ctx).getInt("icon_transparency", 20)
    fun autoMoveToEdge(ctx: Context) = sp(ctx).getBoolean("auto_move_edge", true)
    fun autoActivateRegionMode(ctx: Context) = sp(ctx).getBoolean("auto_region_mode", true)

    // Text style settings (screenshot 3)
    fun upcaseText(ctx: Context) = sp(ctx).getBoolean("upcase_text", false)
    fun textAlignCenter(ctx: Context) = sp(ctx).getBoolean("text_align_center", false)
    fun fontName(ctx: Context) = sp(ctx).getString("font_name", "Roboto-Medium") ?: "Roboto-Medium"

    // Other settings (screenshot 1)
    fun accessibilityMode(ctx: Context) = sp(ctx).getBoolean("accessibility_mode", false)
    fun oneTouchClose(ctx: Context) = sp(ctx).getBoolean("one_touch_close", true)
    fun hideCloseIcon(ctx: Context) = sp(ctx).getBoolean("hide_close_icon", true)
    fun hideSettingsIcon(ctx: Context) = sp(ctx).getBoolean("hide_settings_icon", true)
    fun originalTextVertical(ctx: Context) = sp(ctx).getBoolean("vertical_text", true)

    // Misc (screenshot 2 "More" menu)
    fun darkTheme(ctx: Context) = sp(ctx).getBoolean("dark_theme", true)

    fun putBool(ctx: Context, key: String, value: Boolean) =
        sp(ctx).edit().putBoolean(key, value).apply()

    fun putInt(ctx: Context, key: String, value: Int) =
        sp(ctx).edit().putInt(key, value).apply()

    fun putString(ctx: Context, key: String, value: String) =
        sp(ctx).edit().putString(key, value).apply()

    fun asMap(ctx: Context): Map<String, Any> = mapOf(
        "source_lang" to sourceLang(ctx),
        "target_lang" to targetLang(ctx),
        "icon_size" to iconSize(ctx),
        "icon_transparency" to iconTransparency(ctx),
        "auto_move_edge" to autoMoveToEdge(ctx),
        "auto_region_mode" to autoActivateRegionMode(ctx),
        "upcase_text" to upcaseText(ctx),
        "text_align_center" to textAlignCenter(ctx),
        "font_name" to fontName(ctx),
        "accessibility_mode" to accessibilityMode(ctx),
        "one_touch_close" to oneTouchClose(ctx),
        "hide_close_icon" to hideCloseIcon(ctx),
        "hide_settings_icon" to hideSettingsIcon(ctx),
        "vertical_text" to originalTextVertical(ctx),
        "dark_theme" to darkTheme(ctx),
    )
}
__EOF_SCRIPT__

mkdir -p "android/app/src/main/kotlin/com/example/screen_translator"
cat > "android/app/src/main/kotlin/com/example/screen_translator/RegionSelectView.kt" << '__EOF_SCRIPT__'
package com.example.screen_translator

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.view.MotionEvent
import android.view.View

/**
 * Full-screen transparent view used only while "Region Mode" is active.
 * The user drags out a rectangle; on release [onSelected] fires with the
 * selected screen rect so OverlayService can crop the capture to it.
 */
class RegionSelectView(
    context: Context,
    private val onSelected: (Rect) -> Unit,
) : View(context) {

    private var startX = 0; private var startY = 0
    private var curX = 0; private var curY = 0
    private var active = false

    private val fillPaint = Paint().apply { color = Color.parseColor("#552196F3") }
    private val strokePaint = Paint().apply {
        color = Color.parseColor("#2196F3"); style = Paint.Style.STROKE; strokeWidth = 4f
    }
    private val dimPaint = Paint().apply { color = Color.parseColor("#66000000") }

    fun begin(anchorX: Int, anchorY: Int) {
        startX = anchorX; startY = anchorY; curX = anchorX; curY = anchorY
        active = true
        invalidate()
    }

    fun updateCurrent(x: Int, y: Int) {
        curX = x; curY = y
        invalidate()
    }

    fun finishSelection() {
        active = false
        val rect = Rect(
            minOf(startX, curX), minOf(startY, curY),
            maxOf(startX, curX), maxOf(startY, curY)
        )
        if (rect.width() > 20 && rect.height() > 20) onSelected(rect)
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        // Region selection is normally driven by the floating icon's own
        // touch handler forwarding coordinates via updateCurrent()/
        // finishSelection(); this override just keeps the view eligible to
        // receive touches if it is ever driven directly.
        when (event.action) {
            MotionEvent.ACTION_MOVE -> updateCurrent(event.rawX.toInt(), event.rawY.toInt())
            MotionEvent.ACTION_UP -> finishSelection()
        }
        return true
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), dimPaint)
        if (!active) return
        val rect = Rect(minOf(startX, curX), minOf(startY, curY), maxOf(startX, curX), maxOf(startY, curY))
        canvas.drawRect(rect, fillPaint)
        canvas.drawRect(rect, strokePaint)
    }
}
__EOF_SCRIPT__

mkdir -p "android/app/src/main/kotlin/com/example/screen_translator"
cat > "android/app/src/main/kotlin/com/example/screen_translator/ScreenCaptureActivity.kt" << '__EOF_SCRIPT__'
package com.example.screen_translator

import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Bundle

/**
 * Invisible activity whose only job is to pop the system "Start recording
 * or casting?" dialog and forward the resulting token to OverlayService,
 * which uses it to grab a single screenshot. Finishes itself immediately
 * after.
 */
class ScreenCaptureActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val manager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        startActivityForResult(manager.createScreenCaptureIntent(), REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE) {
            val intent = Intent(this, OverlayService::class.java).apply {
                action = OverlayService.ACTION_CAPTURE_GRANTED
                putExtra(OverlayService.EXTRA_RESULT_CODE, resultCode)
                putExtra(OverlayService.EXTRA_RESULT_DATA, data)
            }
            startForegroundService(intent)
        }
        finish()
        overridePendingTransition(0, 0)
    }

    companion object {
        private const val REQUEST_CODE = 4201
    }
}
__EOF_SCRIPT__

mkdir -p "android/app/src/main/kotlin/com/example/screen_translator"
cat > "android/app/src/main/kotlin/com/example/screen_translator/TranslateEngine.kt" << '__EOF_SCRIPT__'
package com.example.screen_translator

import com.google.mlkit.common.model.DownloadConditions
import com.google.mlkit.nl.translate.TranslateLanguage
import com.google.mlkit.nl.translate.Translation
import com.google.mlkit.nl.translate.Translator
import com.google.mlkit.nl.translate.TranslatorOptions

/**
 * On-device translation via Google ML Kit Translate. This is free and has
 * no request limits/API key because the small language model is downloaded
 * once (Wi-Fi by default) and then runs entirely on the phone.
 */
object TranslateEngine {

    private var cached: Translator? = null
    private var cachedPair: Pair<String, String>? = null

    private fun clientFor(sourceCode: String, targetCode: String): Translator {
        val pair = sourceCode to targetCode
        if (cachedPair == pair && cached != null) return cached!!

        cached?.close()
        val options = TranslatorOptions.Builder()
            .setSourceLanguage(TranslateLanguage.fromLanguageTag(sourceCode) ?: TranslateLanguage.ENGLISH)
            .setTargetLanguage(TranslateLanguage.fromLanguageTag(targetCode) ?: TranslateLanguage.ARABIC)
            .build()
        val client = Translation.getClient(options)
        cached = client
        cachedPair = pair
        return client
    }

    /** Downloads the language model if needed, then translates [text]. */
    fun translate(
        text: String,
        sourceCode: String,
        targetCode: String,
        onResult: (String) -> Unit,
        onError: (Exception) -> Unit,
    ) {
        val client = clientFor(sourceCode, targetCode)
        val conditions = DownloadConditions.Builder().requireWifi().build()
        client.downloadModelIfNeeded(conditions)
            .addOnSuccessListener {
                client.translate(text)
                    .addOnSuccessListener { onResult(it) }
                    .addOnFailureListener { onError(it) }
            }
            .addOnFailureListener { onError(it) }
    }
}
__EOF_SCRIPT__

mkdir -p "lib"
cat > "lib/main.dart" << '__EOF_SCRIPT__'
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ScreenTranslatorApp());
}

// ============================================================== constants

class AppColors {
  static const background = Color(0xFFF5F5F5);
  static const appBar = Color(0xFF2196F3);
  static const card = Color(0xFFFFFFFF);
}

class TranslationEngine {
  final String id;
  final String name;
  final String description;
  final bool isPro;
  const TranslationEngine({
    required this.id,
    required this.name,
    required this.description,
    this.isPro = false,
  });
}

const List<TranslationEngine> kEngines = [
  TranslationEngine(id: 'google', name: 'Google Translate', description: 'Fast and accurate translation'),
  TranslationEngine(id: 'deep', name: 'Deep Translate', description: 'Smooth and natural translation'),
  TranslationEngine(id: 'gemini', name: 'Gemini AI Translate', description: 'AI translation with smart context', isPro: true),
  TranslationEngine(id: 'chatgpt', name: 'ChatGPT Translate', description: 'AI translation with natural context', isPro: true),
  TranslationEngine(id: 'offline', name: 'Offline Translate', description: 'Offline translation, no internet required', isPro: true),
  TranslationEngine(id: 'yandex', name: 'Yandex Translate', description: 'Reliable translation, optimized for Russian'),
  TranslationEngine(id: 'microsoft', name: 'Microsoft Translator', description: 'Uses the API key you enter in Settings below'),
];

TranslationEngine engineById(String id) =>
    kEngines.firstWhere((e) => e.id == id, orElse: () => kEngines.first);

const Map<String, IconData> kIconChoices = {
  'target': Icons.gps_fixed,
  'camera': Icons.camera_alt,
  'translate': Icons.translate,
  'language': Icons.language,
};

const List<Color> kColorChoices = [
  Colors.black87, Colors.blue, Colors.red, Colors.green, Colors.purple, Colors.orange,
];

const Map<String, String> kLanguages = {
  'en': 'English', 'ar': 'Arabic', 'es': 'Spanish', 'fr': 'French',
  'ja': 'Japanese', 'zh': 'Chinese', 'ko': 'Korean', 'hi': 'Hindi', 'ru': 'Russian',
};

// ================================================================ settings

/// Single source of truth for every switch/selector in the app, persisted
/// via SharedPreferences (works on Web too, backed by localStorage).
class AppSettings extends ChangeNotifier {
  bool running = false;
  String engineId = 'google';
  String sourceLang = 'en';
  String targetLang = 'ar';

  String iconName = 'target';
  int iconColorValue = 0xDD000000; // Colors.black87

  bool autoMoveEdge = true;
  bool autoRegionMode = true;
  bool accessibilityMode = false;
  bool oneTouchClose = true;
  bool hideCloseIcon = true;
  bool hideSettingsIcon = true;
  bool verticalText = true;
  bool darkTheme = false;

  String microsoftApiKey = '';
  String microsoftRegion = '';

  TranslationEngine get engine => engineById(engineId);
  Color get iconColor => Color(iconColorValue);

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    engineId = p.getString('engine_id') ?? engineId;
    sourceLang = p.getString('source_lang') ?? sourceLang;
    targetLang = p.getString('target_lang') ?? targetLang;
    iconName = p.getString('icon_name') ?? iconName;
    iconColorValue = p.getInt('icon_color') ?? iconColorValue;
    autoMoveEdge = p.getBool('auto_move_edge') ?? autoMoveEdge;
    autoRegionMode = p.getBool('auto_region_mode') ?? autoRegionMode;
    accessibilityMode = p.getBool('accessibility_mode') ?? accessibilityMode;
    oneTouchClose = p.getBool('one_touch_close') ?? oneTouchClose;
    hideCloseIcon = p.getBool('hide_close_icon') ?? hideCloseIcon;
    hideSettingsIcon = p.getBool('hide_settings_icon') ?? hideSettingsIcon;
    verticalText = p.getBool('vertical_text') ?? verticalText;
    darkTheme = p.getBool('dark_theme') ?? darkTheme;
    microsoftApiKey = p.getString('ms_api_key') ?? microsoftApiKey;
    microsoftRegion = p.getString('ms_region') ?? microsoftRegion;
    notifyListeners();
  }

  Future<void> _saveBool(String key, bool value) async => (await SharedPreferences.getInstance()).setBool(key, value);
  Future<void> _saveString(String key, String value) async => (await SharedPreferences.getInstance()).setString(key, value);
  Future<void> _saveInt(String key, int value) async => (await SharedPreferences.getInstance()).setInt(key, value);

  void setEngine(String id) {
    engineId = id;
    notifyListeners();
    _saveString('engine_id', id);
  }

  void setLanguages(String source, String target) {
    sourceLang = source;
    targetLang = target;
    notifyListeners();
    _saveString('source_lang', source);
    _saveString('target_lang', target);
  }

  void setIcon(String name) {
    iconName = name;
    notifyListeners();
    _saveString('icon_name', name);
  }

  void setIconColor(Color color) {
    iconColorValue = color.toARGB32();
    notifyListeners();
    _saveInt('icon_color', color.toARGB32());
  }

  void setMicrosoftKey(String key) {
    microsoftApiKey = key;
    notifyListeners();
    _saveString('ms_api_key', key);
  }

  void setMicrosoftRegion(String region) {
    microsoftRegion = region;
    notifyListeners();
    _saveString('ms_region', region);
  }

  void toggleRunning() {
    running = !running;
    notifyListeners();
  }

  void toggleTheme() {
    darkTheme = !darkTheme;
    notifyListeners();
    _saveBool('dark_theme', darkTheme);
  }

  void toggleAutoMoveEdge() { autoMoveEdge = !autoMoveEdge; notifyListeners(); _saveBool('auto_move_edge', autoMoveEdge); }
  void toggleAutoRegionMode() { autoRegionMode = !autoRegionMode; notifyListeners(); _saveBool('auto_region_mode', autoRegionMode); }
  void toggleAccessibilityMode() { accessibilityMode = !accessibilityMode; notifyListeners(); _saveBool('accessibility_mode', accessibilityMode); }
  void toggleOneTouchClose() { oneTouchClose = !oneTouchClose; notifyListeners(); _saveBool('one_touch_close', oneTouchClose); }
  void toggleHideCloseIcon() { hideCloseIcon = !hideCloseIcon; notifyListeners(); _saveBool('hide_close_icon', hideCloseIcon); }
  void toggleHideSettingsIcon() { hideSettingsIcon = !hideSettingsIcon; notifyListeners(); _saveBool('hide_settings_icon', hideSettingsIcon); }
  void toggleVerticalText() { verticalText = !verticalText; notifyListeners(); _saveBool('vertical_text', verticalText); }
}

// ============================================================= translation

/// Where real translation calls live. Only Microsoft Translator is wired to
/// an actual HTTP call (using the key the user enters in Settings) — every
/// other engine needs its own paid API key/SDK plugged in here the same way
/// before it will do anything but show the "not connected" message.
///
/// NOTE for Flutter Web: Azure Cognitive Services does not send permissive
/// CORS headers for browser calls made with a raw subscription key, so a
/// direct call like this will likely be blocked by the browser on Web.
/// The Android build (or any real deployment) should proxy this call
/// through your own backend instead of calling Azure directly from the
/// client — this direct-call version is meant as a starting point / for
/// testing from non-Web platforms.
class TranslationService {
  static Future<String> translate({
    required String text,
    required AppSettings settings,
  }) async {
    if (settings.engineId == 'microsoft') {
      return _translateWithMicrosoft(
        text: text,
        from: settings.sourceLang,
        to: settings.targetLang,
        apiKey: settings.microsoftApiKey,
        region: settings.microsoftRegion,
      );
    }
    await Future.delayed(const Duration(milliseconds: 300));
    throw Exception(
      "${settings.engine.name} isn't connected to a backend yet. Add a "
      "Microsoft Translator key in Settings to try a live translation, or "
      "wire this engine's API in TranslationService the same way.",
    );
  }

  static Future<String> _translateWithMicrosoft({
    required String text,
    required String from,
    required String to,
    required String apiKey,
    required String region,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw Exception('Add your Microsoft Translator API key in Settings first.');
    }
    final uri = Uri.parse(
      'https://api.cognitive.microsofttranslator.com/translate'
      '?api-version=3.0&from=$from&to=$to',
    );
    final response = await http.post(
      uri,
      headers: {
        'Ocp-Apim-Subscription-Key': apiKey,
        if (region.trim().isNotEmpty) 'Ocp-Apim-Subscription-Region': region.trim(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode([
        {'Text': text},
      ]),
    );
    if (response.statusCode != 200) {
      throw Exception('Microsoft Translator error ${response.statusCode}: ${response.body}');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    final translations = data.first['translations'] as List<dynamic>;
    return translations.first['text'] as String;
  }
}

// ==================================================================== app

class ScreenTranslatorApp extends StatefulWidget {
  const ScreenTranslatorApp({super.key});
  @override
  State<ScreenTranslatorApp> createState() => _ScreenTranslatorAppState();
}

class _ScreenTranslatorAppState extends State<ScreenTranslatorApp> {
  final AppSettings settings = AppSettings();

  @override
  void initState() {
    super.initState();
    settings.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'Screen Translator',
          debugShowCheckedModeBanner: false,
          themeMode: settings.darkTheme ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppColors.background,
            cardColor: AppColors.card,
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.appBar, brightness: Brightness.light),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.appBar,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
            ),
            cardTheme: CardThemeData(
              color: AppColors.card,
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.appBar, brightness: Brightness.dark),
          ),
          home: RootShell(settings: settings),
        );
      },
    );
  }
}

class RootShell extends StatefulWidget {
  final AppSettings settings;
  const RootShell({super.key, required this.settings});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeTab(settings: widget.settings),
      TranslateTab(settings: widget.settings),
      const CameraTab(),
      MoreTab(settings: widget.settings),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.g_translate_outlined), selectedIcon: Icon(Icons.g_translate), label: 'Translate'),
          NavigationDestination(icon: Icon(Icons.camera_alt_outlined), selectedIcon: Icon(Icons.camera_alt), label: 'Camera'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

// ============================================================ shared bits

Widget sectionHeader(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );

Widget switchCard({
  required String title,
  String? subtitle,
  required bool value,
  required VoidCallback onChanged,
}) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      onChanged: (_) => onChanged(),
    ),
  );
}

Widget navCard({required String title, required Widget trailing, VoidCallback? onTap}) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: trailing,
      onTap: onTap,
    ),
  );
}

Widget languageDropdown(AppSettings settings, {required bool isSource}) {
  final value = isSource ? settings.sourceLang : settings.targetLang;
  return DropdownButtonHideUnderline(
    child: DropdownButton<String>(
      value: value,
      isExpanded: true,
      items: kLanguages.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
      onChanged: (v) {
        if (v == null) return;
        if (isSource) {
          settings.setLanguages(v, settings.targetLang);
        } else {
          settings.setLanguages(settings.sourceLang, v);
        }
      },
    ),
  );
}

void showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$feature — not implemented in this demo yet.')),
  );
}

void showEngineSheet(BuildContext context, AppSettings settings) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Choose Engine', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetContext)),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: kEngines.map((engine) {
                    final selected = engine.id == settings.engineId;
                    return Card(
                      color: selected ? AppColors.appBar.withValues(alpha: 0.12) : AppColors.card,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(engine.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(engine.description),
                        trailing: engine.isPro
                            ? Chip(
                                label: const Text('PRO', style: TextStyle(fontSize: 11, color: Colors.white)),
                                backgroundColor: Colors.amber.shade700,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              )
                            : null,
                        onTap: () {
                          settings.setEngine(engine.id);
                          Navigator.pop(sheetContext);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void showLanguagePicker(BuildContext context, AppSettings settings) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) {
      // Wrapped in its own AnimatedBuilder so the swap button and dropdowns
      // update live while the sheet stays open.
      return AnimatedBuilder(
        animation: settings,
        builder: (context, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: languageDropdown(settings, isSource: true)),
                    IconButton(
                      icon: const Icon(Icons.swap_horiz),
                      onPressed: () => settings.setLanguages(settings.targetLang, settings.sourceLang),
                    ),
                    Expanded(child: languageDropdown(settings, isSource: false)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void showIconPicker(BuildContext context, AppSettings settings) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Choose icon'),
      content: Wrap(
        spacing: 12,
        children: kIconChoices.entries.map((e) {
          final selected = e.key == settings.iconName;
          return InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              settings.setIcon(e.key);
              Navigator.pop(dialogContext);
            },
            child: CircleAvatar(
              radius: 24,
              backgroundColor: selected ? AppColors.appBar : Colors.grey.shade200,
              child: Icon(e.value, color: selected ? Colors.white : Colors.black87),
            ),
          );
        }).toList(),
      ),
    ),
  );
}

void showColorPicker(BuildContext context, AppSettings settings) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Choose icon color'),
      content: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: kColorChoices.map((color) {
          final selected = color.toARGB32() == settings.iconColorValue;
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              settings.setIconColor(color);
              Navigator.pop(dialogContext);
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: color,
              child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
            ),
          );
        }).toList(),
      ),
    ),
  );
}

// ==================================================================== home

class HomeTab extends StatefulWidget {
  final AppSettings settings;
  const HomeTab({super.key, required this.settings});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late final TextEditingController _keyController;
  late final TextEditingController _regionController;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.settings.microsoftApiKey);
    _regionController = TextEditingController(text: widget.settings.microsoftRegion);
  }

  @override
  void dispose() {
    _keyController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  void _togglePower() {
    widget.settings.toggleRunning();
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "The floating overlay only works in the installed Android app — "
            "this switch is just a UI preview here on Web.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tap Translate Screen'),
        actions: [
          IconButton(icon: const Icon(Icons.help_outline), onPressed: () => showComingSoon(context, 'Help')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: _togglePower,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: settings.running ? AppColors.appBar : Colors.grey, width: 3),
                  color: settings.running ? AppColors.appBar.withValues(alpha: 0.08) : Colors.transparent,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.power_settings_new, size: 40, color: settings.running ? AppColors.appBar : Colors.grey),
                    const SizedBox(height: 4),
                    Text(
                      settings.running ? 'ON' : 'OFF',
                      style: TextStyle(fontWeight: FontWeight.bold, color: settings.running ? AppColors.appBar : Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              settings.running ? 'Stop floating translator' : 'Start floating translator',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              title: Text(settings.engine.name),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () => showEngineSheet(context, settings),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(child: languageDropdown(settings, isSource: true)),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: () => settings.setLanguages(settings.targetLang, settings.sourceLang),
                  ),
                  Expanded(child: languageDropdown(settings, isSource: false)),
                ],
              ),
            ),
          ),

          sectionHeader('Floating Icon Settings'),
          navCard(
            title: 'Icon',
            trailing: Icon(kIconChoices[settings.iconName]),
            onTap: () => showIconPicker(context, settings),
          ),
          navCard(
            title: 'Icon color',
            trailing: CircleAvatar(radius: 12, backgroundColor: settings.iconColor),
            onTap: () => showColorPicker(context, settings),
          ),
          switchCard(
            title: 'Auto-move to screen edge and dim',
            value: settings.autoMoveEdge,
            onChanged: settings.toggleAutoMoveEdge,
          ),
          switchCard(
            title: 'Auto-activate Region Mode',
            subtitle: 'Move the icon, then hold it in place to auto activate Region Mode.',
            value: settings.autoRegionMode,
            onChanged: settings.toggleAutoRegionMode,
          ),

          sectionHeader('Other Settings'),
          switchCard(title: 'Accessibility mode', value: settings.accessibilityMode, onChanged: settings.toggleAccessibilityMode),
          switchCard(title: 'One touch to close floating translation', value: settings.oneTouchClose, onChanged: settings.toggleOneTouchClose),
          switchCard(title: 'Hide "close icon" in floating translation', value: settings.hideCloseIcon, onChanged: settings.toggleHideCloseIcon),
          switchCard(title: 'Hide "settings icon" in floating translation', value: settings.hideSettingsIcon, onChanged: settings.toggleHideSettingsIcon),
          switchCard(
            title: 'Original text is vertical',
            subtitle: 'Apply when translating Chinese, Japanese, Korean',
            value: settings.verticalText,
            onChanged: settings.toggleVerticalText,
          ),

          sectionHeader('Microsoft Translator'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _keyController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Microsoft Translator API Key',
                      border: OutlineInputBorder(),
                      helperText: 'From your Azure Translator resource.',
                    ),
                    onChanged: settings.setMicrosoftKey,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _regionController,
                    decoration: const InputDecoration(
                      labelText: 'Region (optional)',
                      border: OutlineInputBorder(),
                      helperText: 'Only needed for some resource types, e.g. "westeurope".',
                    ),
                    onChanged: settings.setMicrosoftRegion,
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE69C)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFF8A6D3B)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Some manufacturers' Battery Saver may cause background services to "
                          "malfunction and close the floating icon.",
                          style: TextStyle(color: Color(0xFF8A6D3B)),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => showComingSoon(context, 'Troubleshooting guide'),
                          child: const Text(
                            'See details and troubleshooting instructions',
                            style: TextStyle(
                              color: Color(0xFF8A6D3B),
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================== translate

class TranslateTab extends StatefulWidget {
  final AppSettings settings;
  const TranslateTab({super.key, required this.settings});
  @override
  State<TranslateTab> createState() => _TranslateTabState();
}

class _TranslateTabState extends State<TranslateTab> {
  final _inputController = TextEditingController();
  String? _result;
  String? _error;
  bool _loading = false;

  Future<void> _translate() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final translated = await TranslationService.translate(text: text, settings: widget.settings);
      setState(() => _result = translated);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Text Translate')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ActionChip(label: Text(settings.engine.name), onPressed: () => showEngineSheet(context, settings)),
              Chip(label: Text(kLanguages[settings.sourceLang] ?? settings.sourceLang)),
              const Icon(Icons.arrow_forward, size: 16),
              Chip(label: Text(kLanguages[settings.targetLang] ?? settings.targetLang)),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _inputController,
                maxLines: 5,
                decoration: const InputDecoration(border: InputBorder.none, hintText: 'Enter text to translate...'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.appBar,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _loading ? null : _translate,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Translate'),
          ),
          const SizedBox(height: 16),
          if (_result != null) Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(_result!))),
          if (_error != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              ),
            ),
        ],
      ),
    );
  }
}

// ================================================================= camera

class CameraTab extends StatelessWidget {
  const CameraTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Camera translation needs the native Android build (CameraX + on-device OCR) — '
            'not available in this Flutter Web preview.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ==================================================================== more

class MoreTab extends StatelessWidget {
  final AppSettings settings;
  const MoreTab({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, String title, {String? subtitle, Widget? trailing, VoidCallback? onTap}) {
      return ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing,
        onTap: onTap,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tap Translate Screen')),
      body: ListView(
        children: [
          row(
            Icons.g_translate,
            'Language',
            subtitle: '${kLanguages[settings.sourceLang]} \u2192 ${kLanguages[settings.targetLang]}',
            onTap: () => showLanguagePicker(context, settings),
          ),
          row(
            Icons.dark_mode_outlined,
            'Theme',
            subtitle: settings.darkTheme ? 'Dark' : 'Light',
            trailing: Switch(value: settings.darkTheme, onChanged: (_) => settings.toggleTheme()),
          ),
          const Divider(height: 1),
          row(Icons.add_circle_outline, 'Add icon to Quick Access', onTap: () => showComingSoon(context, 'Quick Access')),
          row(Icons.volume_up_outlined, 'Voice Settings', onTap: () => showComingSoon(context, 'Voice Settings')),
          row(
            Icons.grid_view,
            'Screen Capture permission options',
            onTap: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Screen Capture permission'),
                content: const Text(
                  'This is requested automatically by the installed Android app the first '
                  'time you start the floating translator. There is nothing to configure '
                  'here in the Web preview.',
                ),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
              ),
            ),
          ),
          const Divider(height: 1),
          row(Icons.support_agent, 'Support', onTap: () => showComingSoon(context, 'Support')),
          row(Icons.help_outline, 'Tutorial', onTap: () => showComingSoon(context, 'Tutorial')),
          row(Icons.share_outlined, 'Share', onTap: () => showComingSoon(context, 'Share')),
          row(Icons.description_outlined, 'Terms of Service', onTap: () => showComingSoon(context, 'Terms of Service')),
          row(Icons.privacy_tip_outlined, 'Privacy Policy', onTap: () => showComingSoon(context, 'Privacy Policy')),
        ],
      ),
    );
  }
}
__EOF_SCRIPT__

cat > "pubspec.yaml" << '__EOF_SCRIPT__'
name: screen_translator
description: Floating screen translator (OCR + on-device translation), no paid APIs.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6
  shared_preferences: ^2.2.3   # settings persistence (works on Web via localStorage too)
  http: ^1.2.2                 # Microsoft Translator HTTP calls in TranslationService
  # Native ML Kit text-recognition / translation are used on the Android side
  # (see android/app/.../OcrEngine.kt and TranslateEngine.kt) because the
  # floating overlay is a native foreground service that must keep running
  # even while the Flutter UI is closed. lib/main.dart in this build is the
  # Web/UI-preview layer and does not call into that native service.

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
__EOF_SCRIPT__

echo "Project files created under $(pwd)/$PROJECT_DIR"
echo "Next: cd screen_translator && flutter pub get"EOF

