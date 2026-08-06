/// A single daily alarm — MVP scope is one alarm, not a list, matching the
/// alarm screen mockup (no weekday repeat picker either).
class AlarmConfig {
  final bool enabled;
  final int hour; // 0-23
  final int minute; // 0-59
  final String soundId;

  const AlarmConfig({
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.soundId,
  });

  static const fallback = AlarmConfig(enabled: false, hour: 7, minute: 0, soundId: 'soft_piano');

  AlarmConfig copyWith({bool? enabled, int? hour, int? minute, String? soundId}) => AlarmConfig(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        soundId: soundId ?? this.soundId,
      );
}
