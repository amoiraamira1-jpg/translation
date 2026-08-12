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
