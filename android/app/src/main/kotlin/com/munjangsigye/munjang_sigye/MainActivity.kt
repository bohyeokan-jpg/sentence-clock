package com.munjangsigye.munjang_sigye

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Android doesn't let a regular app silently set itself as the active
// screen saver (that needs WRITE_SECURE_SETTINGS, a system-only
// permission) — the user has to pick it themselves in Settings. This
// channel just opens that settings page directly (Settings > Display >
// Screen saver / Daydream) instead of making them dig through the OS
// Settings app to find it.
private const val CHANNEL = "com.munjangsigye.munjang_sigye/dream_settings"

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openDreamSettings" -> {
                    startActivity(Intent(Settings.ACTION_DREAM_SETTINGS))
                    result.success(null)
                }
                // Runs the exact same FlipClockRenderer as the real Daydream,
                // fullscreen inside the app — see DreamPreviewActivity.
                "openDreamPreview" -> {
                    startActivity(Intent(this, DreamPreviewActivity::class.java))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
