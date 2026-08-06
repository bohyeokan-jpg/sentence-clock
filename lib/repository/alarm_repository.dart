import 'package:alarm/alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/alarm_config.dart';
import '../model/alarm_sound.dart';

/// Persists the single daily alarm and schedules/cancels it with the
/// `alarm` plugin. Since there's no weekday picker in this MVP, a fired
/// alarm is rescheduled for the same time the next day from the ringing
/// screen (see AlarmRingingScreen).
class AlarmRepository {
  static const _enabledKey = 'alarm_enabled';
  static const _hourKey = 'alarm_hour';
  static const _minuteKey = 'alarm_minute';
  static const _soundKey = 'alarm_sound_id';
  static const alarmId = 1;

  Future<AlarmConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AlarmConfig(
      enabled: prefs.getBool(_enabledKey) ?? AlarmConfig.fallback.enabled,
      hour: prefs.getInt(_hourKey) ?? AlarmConfig.fallback.hour,
      minute: prefs.getInt(_minuteKey) ?? AlarmConfig.fallback.minute,
      soundId: prefs.getString(_soundKey) ?? AlarmConfig.fallback.soundId,
    );
  }

  Future<void> save(AlarmConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, config.enabled);
    await prefs.setInt(_hourKey, config.hour);
    await prefs.setInt(_minuteKey, config.minute);
    await prefs.setString(_soundKey, config.soundId);

    if (config.enabled) {
      await _schedule(config);
    } else {
      await Alarm.stop(alarmId);
    }
  }

  Future<void> _schedule(AlarmConfig config) async {
    final sound = alarmSoundById(config.soundId);
    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: alarmId,
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

  /// Reschedules the same alarm for the next day — called after the
  /// ringing screen's stop button, so the daily alarm keeps repeating.
  Future<void> rescheduleForTomorrow(AlarmConfig config) async {
    if (!config.enabled) return;
    await _schedule(config);
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
