import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings.dart';

/// Simple type-to-translate tab. The actual translation still happens on
/// the Android side (TranslateEngine.kt / ML Kit) — wire this text field up
/// to a new "translateText" MethodChannel call the same way NativeBridge
/// wires the other native calls, if you want this tab to be fully live.
class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});
  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Translate')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Chip(label: Text(settings.sourceLang.toUpperCase())),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward)),
                Chip(label: Text(settings.targetLang.toUpperCase())),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Type text to translate'),
            ),
          ],
        ),
      ),
    );
  }
}
