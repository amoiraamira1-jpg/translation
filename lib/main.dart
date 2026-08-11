import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/settings.dart';
import 'screens/home_screen.dart';
import 'screens/translate_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/more_menu_screen.dart';

void main() {
  runApp(const ScreenTranslatorApp());
}

class ScreenTranslatorApp extends StatelessWidget {
  const ScreenTranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsModel()..load(),
      child: Consumer<SettingsModel>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Screen Translator',
            debugShowCheckedModeBanner: false,
            themeMode: settings.darkTheme ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(brightness: Brightness.light, useMaterial3: true, primaryColor: const Color(0xFF3B5BFE)),
            darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true, primaryColor: const Color(0xFF3B5BFE)),
            home: const RootShell(),
          );
        },
      ),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    TranslateScreen(),
    CameraScreen(),
    MoreMenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.translate_outlined), selectedIcon: Icon(Icons.translate), label: 'Translate'),
          NavigationDestination(icon: Icon(Icons.camera_alt_outlined), selectedIcon: Icon(Icons.camera_alt), label: 'Camera'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
