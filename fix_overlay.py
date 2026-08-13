import re
base = "android/app/src/main/kotlin/com/example/screen_translator"
p1 = f"{base}/OverlayService.kt"
s = open(p1, encoding="utf-8").read()
old_create = """    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        startForeground(NOTIF_ID, buildNotification())
    }"""
new_create = """    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
    }"""
if old_create not in s: raise SystemExit("FAIL: onCreate not found")
s = s.replace(old_create, new_create, 1)
old_start = """    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
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
    }"""
new_start = """    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
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
    }"""
if old_start not in s: raise SystemExit("FAIL: onStartCommand not found")
s = s.replace(old_start, new_start, 1)
open(p1, "w", encoding="utf-8").write(s)
print("OverlayService.kt patched OK")
p2 = f"{base}/MainActivity.kt"
s2 = open(p2, encoding="utf-8").read()
old_main = """                        "startOverlayService" -> {
                                val intent = Intent(this, OverlayService::class.java).apply {
                                        action = OverlayService.ACTION_START
                                }
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent)
                                else startService(intent)
                                result.success(null)
                        }"""
new_main = """                        "startOverlayService" -> {
                                startActivity(Intent(this, ScreenCaptureActivity::class.java).apply {
                                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                })
                                result.success(null)
                        }"""
if old_main not in s2: raise SystemExit("FAIL: startOverlayService not found in MainActivity.kt")
s2 = s2.replace(old_main, new_main, 1)
open(p2, "w", encoding="utf-8").write(s2)
print("MainActivity.kt patched OK")
print("ALL PATCHES APPLIED SUCCESSFULLY")
