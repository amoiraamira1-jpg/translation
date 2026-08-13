p = "android/app/src/main/kotlin/com/example/screen_translator/OverlayService.kt"
s = open(p, encoding="utf-8").read()

old1 = "alpha = 1f - (Prefs.iconTransparency(this@OverlayService) / 100f)"
new1 = "alpha = Prefs.iconTransparency(this@OverlayService) / 100f"
if old1 not in s:
    raise SystemExit("FAIL: pattern 1 not found")
s = s.replace(old1, new1, 1)

old2 = "icon.alpha = 1f - (Prefs.iconTransparency(this) / 100f)"
new2 = "icon.alpha = Prefs.iconTransparency(this) / 100f"
if old2 not in s:
    raise SystemExit("FAIL: pattern 2 not found")
s = s.replace(old2, new2, 1)

open(p, "w", encoding="utf-8").write(s)
print("ALL PATCHES APPLIED SUCCESSFULLY")
