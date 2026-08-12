import 'package:flutter/services.dart';

/// Talks to MainActivity.kt's method channel for the two things only
/// native Android can do: open the OS's own Screen saver settings page
/// (`openDreamSettings`), and run the flip-clock screen saver fullscreen
/// inside the app for a quick check (`openDreamPreview`, backed by
/// DreamPreviewActivity — the same FlipClockRenderer as the real Daydream).
const dreamChannel = MethodChannel('com.munjangsigye.munjang_sigye/dream_settings');
