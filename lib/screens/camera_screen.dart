import 'package:flutter/material.dart';

/// Placeholder for camera-based translation (point the camera at a sign,
/// menu, etc.). Wire this to CameraX + OcrEngine.kt + TranslateEngine.kt via
/// a MethodChannel the same way OverlayService captures the screen, if you
/// want live camera translation rather than just the floating-icon flow.
class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Camera translation not wired up yet — the floating-icon flow '
            '(Home tab) already does screen OCR + on-device translation.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
