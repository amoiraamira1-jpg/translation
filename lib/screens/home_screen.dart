import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings.dart';
import '../services/native_bridge.dart';
import '../widgets/section_header.dart';
import '../widgets/settings_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _running = false;

  Future<void> _toggleService(bool value) async {
    if (value) {
      final granted = await NativeBridge.hasOverlayPermission();
      if (!granted) {
        await NativeBridge.requestOverlayPermission();
        return; // user must flip the switch again once permission is granted
      }
      await NativeBridge.startOverlayService();
    } else {
      await NativeBridge.stopOverlayService();
    }
    setState(() => _running = value);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tap Translate Screen'),
        actions: [
          IconButton(icon: const Icon(Icons.help_outline), onPressed: () {}),
        ],
      ),
      body: ListView(
        children: [
          // Not in the reference screenshots, but required in practice:
          // SYSTEM_ALERT_WINDOW is a special permission the user must grant
          // manually, and the overlay is a foreground service the user
          // should be able to start/stop from Home.
          SwitchListTile(
            title: const Text('Floating translator'),
            subtitle: Text(_running ? 'Running — tap the icon over any app' : 'Off'),
            value: _running,
            onChanged: _toggleService,
          ),
          const Divider(height: 1),

          const SectionHeader('Text Style Settings'),
          SettingsTile.nav(title: 'Style', value: 'Default', onTap: () {}),
          SettingsTile.nav(title: 'Font', value: settings.fontName, onTap: () {}),
          SettingsTile.toggle(
            title: 'Upcase text',
            value: settings.upcaseText,
            onChanged: (v) => settings.setBool('upcase_text', v, () => settings.upcaseText = v),
          ),
          SettingsTile.toggle(
            title: 'Text align center',
            value: settings.textAlignCenter,
            onChanged: (v) => settings.setBool('text_align_center', v, () => settings.textAlignCenter = v),
          ),

          const SectionHeader('Floating Icon Settings'),
          SettingsTile.nav(title: 'Icon', value: '', onTap: () {}),
          SettingsTile.nav(title: 'Icon color', value: '', onTap: () {}),
          SettingsTile.slider(
            title: 'Icon size',
            value: settings.iconSize,
            min: 20,
            max: 80,
            onChanged: (v) => settings.setInt('icon_size', v, () => settings.iconSize = v),
          ),
          SettingsTile.slider(
            title: 'Icon transparency',
            value: settings.iconTransparency,
            min: 0,
            max: 100,
            onChanged: (v) => settings.setInt('icon_transparency', v, () => settings.iconTransparency = v),
          ),
          SettingsTile.toggle(
            title: 'Auto-move to screen edge and dim',
            value: settings.autoMoveToEdge,
            onChanged: (v) => settings.setBool('auto_move_edge', v, () => settings.autoMoveToEdge = v),
          ),
          SettingsTile.toggle(
            title: 'Auto-activate Region Mode',
            subtitle: 'Move the icon, then hold it in place to auto activate Region Mode.',
            value: settings.autoActivateRegionMode,
            onChanged: (v) => settings.setBool('auto_region_mode', v, () => settings.autoActivateRegionMode = v),
          ),

          const SectionHeader('Other Settings'),
          SettingsTile.toggle(
            title: 'Accessibility mode',
            value: settings.accessibilityMode,
            onChanged: (v) => settings.setBool('accessibility_mode', v, () => settings.accessibilityMode = v),
          ),
          SettingsTile.toggle(
            title: 'One touch to close floating translation',
            value: settings.oneTouchClose,
            onChanged: (v) => settings.setBool('one_touch_close', v, () => settings.oneTouchClose = v),
          ),
          SettingsTile.toggle(
            title: 'Hide "close icon" in floating translation',
            value: settings.hideCloseIcon,
            onChanged: (v) => settings.setBool('hide_close_icon', v, () => settings.hideCloseIcon = v),
          ),
          SettingsTile.toggle(
            title: 'Hide "settings icon" in floating translation',
            value: settings.hideSettingsIcon,
            onChanged: (v) => settings.setBool('hide_settings_icon', v, () => settings.hideSettingsIcon = v),
          ),
          SettingsTile.toggle(
            title: 'Original text is vertical',
            subtitle: 'Apply when translating Chinese, Japanese, Korean',
            value: settings.originalTextVertical,
            onChanged: (v) => settings.setBool('vertical_text', v, () => settings.originalTextVertical = v),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Some manufacturers\' battery saver may stop the background '
                'service and close the floating icon — whitelist this app in '
                'your battery settings.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
