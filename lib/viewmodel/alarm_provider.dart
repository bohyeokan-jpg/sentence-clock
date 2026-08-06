import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/alarm_config.dart';
import '../repository/alarm_repository.dart';

class AlarmNotifier extends AsyncNotifier<AlarmConfig> {
  final _repo = AlarmRepository();

  @override
  Future<AlarmConfig> build() => _repo.load();

  Future<void> save(AlarmConfig config) async {
    state = AsyncData(config);
    await _repo.save(config);
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
