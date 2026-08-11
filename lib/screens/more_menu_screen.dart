import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings.dart';
import '../services/native_bridge.dart';

class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsModel>();
    Widget row(IconData icon, String title, {String? subtitle, VoidCallback? onTap}) {
      return ListTile(leading: Icon(icon), title: Text(title), subtitle: subtitle != null ? Text(subtitle) : null, onTap: onTap);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tap Translate Screen')),
      body: ListView(
        children: [
          row(Icons.g_translate, 'Language',
              subtitle: '${settings.sourceLang.toUpperCase()} → ${settings.targetLang.toUpperCase()}',
              onTap: () => _showLanguagePicker(context, settings)),
          row(Icons.dark_mode_outlined, 'Theme',
              subtitle: settings.darkTheme ? 'Dark' : 'Light',
              onTap: () => settings.setBool('dark_theme', !settings.darkTheme, () => settings.darkTheme = !settings.darkTheme)),
          const Divider(height: 1),
          row(Icons.add_circle_outline, 'Add icon to Quick Access', onTap: () {}),
          row(Icons.volume_up_outlined, 'Voice Settings', onTap: () {}),
          row(Icons.grid_view, 'Screen Capture permission options', onTap: () async {
            final granted = await NativeBridge.hasOverlayPermission();
            if (!granted) await NativeBridge.requestOverlayPermission();
          }),
          const Divider(height: 1),
          row(Icons.support_agent, 'Support', onTap: () {}),
          row(Icons.help_outline, 'Tutorial', onTap: () {}),
          row(Icons.share_outlined, 'Share', onTap: () {}),
          row(Icons.description_outlined, 'Terms of Service', onTap: () {}),
          row(Icons.privacy_tip_outlined, 'Privacy Policy', onTap: () {}),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, SettingsModel settings) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            children: const [
              // ML Kit TranslateLanguage codes — extend as needed.
              _LangPair('en', 'ar'), _LangPair('en', 'es'), _LangPair('en', 'fr'),
              _LangPair('ar', 'en'), _LangPair('ja', 'en'), _LangPair('zh', 'en'),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangPair extends StatelessWidget {
  final String source;
  final String target;
  const _LangPair(this.source, this.target);

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsModel>();
    return ActionChip(
      label: Text('${source.toUpperCase()} → ${target.toUpperCase()}'),
      onPressed: () {
        settings.setLanguages(source, target);
        Navigator.pop(context);
      },
    );
  }
}
