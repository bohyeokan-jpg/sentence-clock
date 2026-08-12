import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/dream_background.dart';
import '../service/widget_sync_service.dart';

const _dreamBackgroundKey = 'dream_background_id';

class DreamBackgroundNotifier extends Notifier<DreamBackgroundId> {
  final _widgetSync = WidgetSyncService();

  @override
  DreamBackgroundId build() {
    _restore();
    return DreamBackgroundId.none;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_dreamBackgroundKey);
    final match = saved == null ? null : DreamBackgroundId.values.where((e) => e.name == saved);
    if (match != null && match.isNotEmpty) state = match.first;
    unawaited(_widgetSync.syncDreamBackground(state));
  }

  Future<void> select(DreamBackgroundId id) async {
    state = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dreamBackgroundKey, id.name);
    await _widgetSync.syncDreamBackground(id);
  }
}

final dreamBackgroundProvider = NotifierProvider<DreamBackgroundNotifier, DreamBackgroundId>(
  DreamBackgroundNotifier.new,
);
