path = "lib/main.dart"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

old_import = "import 'package:shared_preferences/shared_preferences.dart';"
new_import = "import 'package:shared_preferences/shared_preferences.dart';\nimport 'package:flutter/services.dart';"
assert content.count(old_import) == 1, "import not found or not unique"
content = content.replace(old_import, new_import, 1)

old_main = "void main() {"
new_main = "const MethodChannel _nativeChannel = MethodChannel('screen_translator/native');\n\nvoid main() {"
assert content.count(old_main) == 1, "main() not found or not unique"
content = content.replace(old_main, new_main, 1)

old_toggle = "  void toggleRunning() {\n    running = !running;\n    notifyListeners();\n  }"
new_toggle = ("  Future<void> toggleRunning() async {\n"
              "    if (!running) {\n"
              "      if (!kIsWeb) {\n"
              "        final hasPermission =\n"
              "            await _nativeChannel.invokeMethod('hasOverlayPermission') as bool? ?? false;\n"
              "        if (!hasPermission) {\n"
              "          await _nativeChannel.invokeMethod('requestOverlayPermission');\n"
              "          return;\n"
              "        }\n"
              "        await _nativeChannel.invokeMethod('startOverlayService');\n"
              "      }\n"
              "      running = true;\n"
              "    } else {\n"
              "      if (!kIsWeb) {\n"
              "        await _nativeChannel.invokeMethod('stopOverlayService');\n"
              "      }\n"
              "      running = false;\n"
              "    }\n"
              "    notifyListeners();\n"
              "  }")
assert content.count(old_toggle) == 1, "toggleRunning() not found or not unique"
content = content.replace(old_toggle, new_toggle, 1)

old_tp = "  void _togglePower() {\n    widget.settings.toggleRunning();"
new_tp = "  void _togglePower() async {\n    await widget.settings.toggleRunning();"
assert content.count(old_tp) == 1, "_togglePower() not found or not unique"
content = content.replace(old_tp, new_tp, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print("DONE - all 4 edits applied successfully")
