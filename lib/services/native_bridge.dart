import 'package:flutter/services.dart';

/// Thin wrapper around the platform channel implemented in
/// android/.../MainActivity.kt. Every call here is mirrored by a `when`
/// branch on the native side.
class NativeBridge {
  NativeBridge._();
  static const _channel = MethodChannel('screen_translator/native');

  static Future<bool> hasOverlayPermission() async {
    final result = await _channel.invokeMethod<bool>('hasOverlayPermission');
    return result ?? false;
  }

  static Future<void> requestOverlayPermission() =>
      _channel.invokeMethod('requestOverlayPermission');

  static Future<void> startOverlayService() =>
      _channel.invokeMethod('startOverlayService');

  static Future<void> stopOverlayService() =>
      _channel.invokeMethod('stopOverlayService');

  static Future<Map<String, dynamic>> getSettings() async {
    final result = await _channel.invokeMethod('getSettings');
    return Map<String, dynamic>.from(result as Map);
  }

  static Future<void> setBool(String key, bool value) =>
      _channel.invokeMethod('setBool', {'key': key, 'value': value});

  static Future<void> setInt(String key, int value) =>
      _channel.invokeMethod('setInt', {'key': key, 'value': value});

  static Future<void> setLanguages(String source, String target) =>
      _channel.invokeMethod('setLanguages', {'source': source, 'target': target});
}
