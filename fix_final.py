# --- 1) Fix OverlayService.kt alpha (already correct formula from before,
#     but let's also clamp so a bad saved value never fully hides the icon)
p1 = "android/app/src/main/kotlin/com/example/screen_translator/OverlayService.kt"
s1 = open(p1, encoding="utf-8").read()

old_a = "alpha = Prefs.iconTransparency(this@OverlayService) / 100f"
new_a = "alpha = (Prefs.iconTransparency(this@OverlayService) / 100f).coerceIn(0.15f, 1f)"
if old_a not in s1:
    raise SystemExit("FAIL: alpha pattern 1 not found")
s1 = s1.replace(old_a, new_a, 1)

old_b = "icon.alpha = Prefs.iconTransparency(this) / 100f"
new_b = "icon.alpha = (Prefs.iconTransparency(this) / 100f).coerceIn(0.15f, 1f)"
if old_b not in s1:
    raise SystemExit("FAIL: alpha pattern 2 not found")
s1 = s1.replace(old_b, new_b, 1)

# --- 2) Fix requestCapture() in OverlayService.kt: drop FLAG_ACTIVITY_NEW_TASK
old_c = """startActivity(Intent(this, ScreenCaptureActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        })"""
if old_c not in s1:
    raise SystemExit("FAIL: NEW_TASK pattern not found in OverlayService.kt")
new_c = "startActivity(Intent(this, ScreenCaptureActivity::class.java))"
s1 = s1.replace(old_c, new_c, 1)

open(p1, "w", encoding="utf-8").write(s1)
print("OverlayService.kt patched OK")

# --- 3) Fix MainActivity.kt: drop FLAG_ACTIVITY_NEW_TASK too
p2 = "android/app/src/main/kotlin/com/example/screen_translator/MainActivity.kt"
s2 = open(p2, encoding="utf-8").read()

old_d = """startActivity(Intent(this, ScreenCaptureActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    })"""
if old_d not in s2:
    raise SystemExit("FAIL: NEW_TASK pattern not found in MainActivity.kt")
new_d = "startActivity(Intent(this, ScreenCaptureActivity::class.java))"
s2 = s2.replace(old_d, new_d, 1)

open(p2, "w", encoding="utf-8").write(s2)
print("MainActivity.kt patched OK")
print("ALL PATCHES APPLIED SUCCESSFULLY")
