import 'package:flutter/foundation.dart';
import '../services/native_bridge.dart';

/// Mirrors android/.../Prefs.kt. Loaded once at startup, then every setter
/// updates local state immediately (for a snappy UI) and pushes the change
/// to native in the background so the always-on OverlayService picks it up
/// right away, even though it has no Flutter engine of its own.
class SettingsModel extends ChangeNotifier {
  String sourceLang = 'en';
  String targetLang = 'ar';

  int iconSize = 35;
  int iconTransparency = 20;
  bool autoMoveToEdge = true;
  bool autoActivateRegionMode = true;

  bool upcaseText = false;
  bool textAlignCenter = false;
  String fontName = 'Roboto-Medium';

  bool accessibilityMode = false;
  bool oneTouchClose = true;
  bool hideCloseIcon = true;
  bool hideSettingsIcon = true;
  bool originalTextVertical = true;

  bool darkTheme = true;

  Future<void> load() async {
    final m = await NativeBridge.getSettings();
    sourceLang = m['source_lang'] ?? sourceLang;
    targetLang = m['target_lang'] ?? targetLang;
    iconSize = m['icon_size'] ?? iconSize;
    iconTransparency = m['icon_transparency'] ?? iconTransparency;
    autoMoveToEdge = m['auto_move_edge'] ?? autoMoveToEdge;
    autoActivateRegionMode = m['auto_region_mode'] ?? autoActivateRegionMode;
    upcaseText = m['upcase_text'] ?? upcaseText;
    textAlignCenter = m['text_align_center'] ?? textAlignCenter;
    fontName = m['font_name'] ?? fontName;
    accessibilityMode = m['accessibility_mode'] ?? accessibilityMode;
    oneTouchClose = m['one_touch_close'] ?? oneTouchClose;
    hideCloseIcon = m['hide_close_icon'] ?? hideCloseIcon;
    hideSettingsIcon = m['hide_settings_icon'] ?? hideSettingsIcon;
    originalTextVertical = m['vertical_text'] ?? originalTextVertical;
    darkTheme = m['dark_theme'] ?? darkTheme;
    notifyListeners();
  }

  Future<void> setBool(String key, bool value, void Function() applyLocally) async {
    applyLocally();
    notifyListeners();
    await NativeBridge.setBool(key, value);
  }

  Future<void> setInt(String key, int value, void Function() applyLocally) async {
    applyLocally();
    notifyListeners();
    await NativeBridge.setInt(key, value);
  }

  Future<void> setLanguages(String source, String target) async {
    sourceLang = source;
    targetLang = target;
    notifyListeners();
    await NativeBridge.setLanguages(source, target);
  }
}
