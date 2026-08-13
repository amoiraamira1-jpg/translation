import re

p2 = "android/app/src/main/kotlin/com/example/screen_translator/MainActivity.kt"
s2 = open(p2, encoding="utf-8").read()

pattern = re.compile(
    r'([ \t]*)"startOverlayService"\s*->\s*\{\s*'
    r'val intent = Intent\(this, OverlayService::class\.java\)\.apply \{\s*'
    r'action = OverlayService\.ACTION_START\s*'
    r'\}\s*'
    r'if \(Build\.VERSION\.SDK_INT >= Build\.VERSION_CODES\.O\) startForegroundService\(intent\)\s*'
    r'else startService\(intent\)\s*'
    r'result\.success\(null\)\s*'
    r'\}',
    re.DOTALL
)

m = pattern.search(s2)
if not m:
    raise SystemExit("FAIL: pattern still not matched")

indent = m.group(1)
i1 = indent + "    "
i2 = indent + "        "

new_block = (
    f'{indent}"startOverlayService" -> {{\n'
    f'{i1}startActivity(Intent(this, ScreenCaptureActivity::class.java).apply {{\n'
    f'{i2}addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)\n'
    f'{i1}}})\n'
    f'{i1}result.success(null)\n'
    f'{indent}}}'
)

s2 = s2[:m.start()] + new_block + s2[m.end():]
open(p2, "w", encoding="utf-8").write(s2)
print("MainActivity.kt patched OK")
print("ALL PATCHES APPLIED SUCCESSFULLY")
