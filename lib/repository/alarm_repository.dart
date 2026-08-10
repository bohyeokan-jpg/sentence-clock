import 'package:alarm/alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/alarm_config.dart';
import '../model/alarm_sound.dart';

/// Persists up to [maxAlarms] daily alarms (slot 0/1/2) and schedules/cancels
/// each with the `alarm` plugin under its own id, so all three can be armed
/// at once. Since there's no weekday picker in this MVP, a fired alarm is
/// rescheduled for the same time the next day from the ringing screen (see
/// AlarmRingingScreen) — using the id the `alarm` plugin reports for the one
/// that actually rang, so the right slot gets rescheduled.
class AlarmRepository {
  static const maxAlarms = 3;

  /// Slot index -> the id the `alarm` plugin schedules/reports it under.
  static int alarmIdFor(int index) => index + 1;

  Future<List<AlarmConfig>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return List.generate(maxAlarms, (i) {
      // Slot 0 falls back to the old un-suffixed keys from before multiple
      // alarms existed, so an already-set single alarm survives the upgrade
      // instead of silently reverting to the fallback default.
      final enabled = prefs.getBool('alarm_enabled_$i') ??
          (i == 0 ? prefs.getBool('alarm_enabled') : null) ??
          AlarmConfig.fallback.enabled;
      final hour = prefs.getInt('alarm_hour_$i') ??
          (i == 0 ? prefs.getInt('alarm_hour') : null) ??
          AlarmConfig.fallback.hour;
      final minute = prefs.getInt('alarm_minute_$i') ??
          (i == 0 ? prefs.getInt('alarm_minute') : null) ??
          AlarmConfig.fallback.minute;
      final soundId = prefs.getString('alarm_sound_id_$i') ??
          (i == 0 ? prefs.getString('alarm_sound_id') : null) ??
          AlarmConfig.fallback.soundId;
      return AlarmConfig(enabled: enabled, hour: hour, minute: minute, soundId: soundId);
    });
  }

  Future<void> saveAt(int index, AlarmConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alarm_enabled_$index', config.enabled);
    await prefs.setInt('alarm_hour_$index', config.hour);
    await prefs.setInt('alarm_minute_$index', config.minute);
    await prefs.setString('alarm_sound_id_$index', config.soundId);

    final id = alarmIdFor(index);
    if (config.enabled) {
      await _schedule(id, config);
    } else {
      await Alarm.stop(id);
    }
  }

  Future<void> _schedule(int id, AlarmConfig config) async {
    final sound = alarmSoundById(config.soundId);
    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: id,
        dateTime: _nextOccurrence(config.hour, config.minute),
        assetAudioPath: sound.assetPath,
        loopAudio: true,
        vibrate: true,
        volume: 0.8,
        fadeDuration: 5.0,
        androidFullScreenIntent: true,
        notificationTitle: '문장시계 알람',
        notificationBody: '일어날 시간이에요',
      ),
    );
  }

  /// Reschedules one fired alarm (identified by the id the `alarm` plugin
  /// rang it under) for the next day — called after the ringing screen's
  /// stop button, so each daily alarm keeps repeating independently.
  Future<void> rescheduleForTomorrow(int id, AlarmConfig config) async {
    if (!config.enabled) return;
    await _schedule(id, config);
  }

  DateTime _nextOccurrence(int hour, int minute) {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }
}
