import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/alarm_config.dart';
import '../repository/alarm_repository.dart';
import '../service/widget_sync_service.dart';

class AlarmNotifier extends AsyncNotifier<AlarmConfig> {
  final _repo = AlarmRepository();
  final _widgetSync = WidgetSyncService();

  @override
  Future<AlarmConfig> build() async {
    final config = await _repo.load();
    unawaited(_widgetSync.syncAlarm(config));
    return config;
  }

  Future<void> save(AlarmConfig config) async {
    state = AsyncData(config);
    await _repo.save(config);
    unawaited(_widgetSync.syncAlarm(config));
  }

  Future<void> setEnabled(bool enabled) async {
    final current = state.value ?? AlarmConfig.fallback;
    await save(current.copyWith(enabled: enabled));
  }

  Future<void> reschedule() async {
    final current = state.value;
    if (current != null) await _repo.rescheduleForTomorrow(current);
  }
}

final alarmProvider = AsyncNotifierProvider<AlarmNotifier, AlarmConfig>(AlarmNotifier.new);
