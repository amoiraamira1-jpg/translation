package com.example.screen_translator

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "screen_translator/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasOverlayPermission" ->
                    result.success(Settings.canDrawOverlays(this))

                "requestOverlayPermission" -> {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:$packageName")
                    )
                    startActivity(intent)
                    result.success(null)
                }

                "startOverlayService" -> {
                    val intent = Intent(this, OverlayService::class.java).apply {
                        action = OverlayService.ACTION_START
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent)
                    else startService(intent)
                    result.success(null)
                }

                "stopOverlayService" -> {
                    startService(Intent(this, OverlayService::class.java).apply {
                        action = OverlayService.ACTION_STOP
                    })
                    result.success(null)
                }

                "getSettings" -> result.success(Prefs.asMap(this))

                "setBool" -> {
                    val key = call.argument<String>("key")!!
                    val value = call.argument<Boolean>("value")!!
                    Prefs.putBool(this, key, value)
                    result.success(null)
                }

                "setInt" -> {
                    val key = call.argument<String>("key")!!
                    val value = call.argument<Int>("value")!!
                    Prefs.putInt(this, key, value)
                    result.success(null)
                }

                "setLanguages" -> {
                    val source = call.argument<String>("source")!!
                    val target = call.argument<String>("target")!!
                    Prefs.setLanguages(this, source, target)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }
}
