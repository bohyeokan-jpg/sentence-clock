import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/alarm_config.dart';
import '../repository/alarm_repository.dart';
import '../service/widget_sync_service.dart';

/// The first *enabled* alarm, top slot first — this is the one shown as the
/// red hand on the clock (in-app and widget) and in the settings summary,
/// since only one hand fits on a clock face regardless of how many alarms
/// are armed.
AlarmConfig? topEnabledAlarm(List<AlarmConfig> alarms) {
  for (final alarm in alarms) {
    if (alarm.enabled) return alarm;
  }
  return null;
}

class AlarmNotifier extends AsyncNotifier<List<AlarmConfig>> {
  final _repo = AlarmRepository();
  final _widgetSync = WidgetSyncService();

  @override
  Future<List<AlarmConfig>> build() async {
    final alarms = await _repo.load();
    unawaited(_widgetSync.syncAlarm(topEnabledAlarm(alarms)));
    return alarms;
  }

  Future<void> saveAt(int index, AlarmConfig config) async {
    final current = List<AlarmConfig>.of(state.value ?? const []);
    if (index < 0 || index >= current.length) return;
    current[index] = config;
    state = AsyncData(current);
    await _repo.saveAt(index, config);
    unawaited(_widgetSync.syncAlarm(topEnabledAlarm(current)));
  }

  Future<void> setEnabled(int index, bool enabled) async {
    final current = state.value;
    if (current == null || index < 0 || index >= current.length) return;
    await saveAt(index, current[index].copyWith(enabled: enabled));
  }

  /// Reschedules the one alarm that just rang, identified by the id the
  /// `alarm` plugin reports (see AlarmRepository.alarmIdFor) — not "the"
  /// alarm, since up to three can be armed independently now.
  Future<void> reschedule(int ringingAlarmId) async {
    final current = state.value;
    if (current == null) return;
    final index = ringingAlarmId - 1;
    if (index < 0 || index >= current.length) return;
    await _repo.rescheduleForTomorrow(ringingAlarmId, current[index]);
  }
}

final alarmProvider = AsyncNotifierProvider<AlarmNotifier, List<AlarmConfig>>(AlarmNotifier.new);

/// Convenience read of just the topmost-enabled alarm, for screens (main
/// clock, settings summary) that only care about the one shown on the dial.
final topAlarmProvider = Provider<AlarmConfig?>((ref) {
  final alarms = ref.watch(alarmProvider).value;
  return alarms == null ? null : topEnabledAlarm(alarms);
});
