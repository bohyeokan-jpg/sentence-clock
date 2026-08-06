import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/clock_shape.dart';

const _clockShapeKey = 'clock_shape';

class ClockShapeNotifier extends Notifier<ClockShape> {
  @override
  ClockShape build() {
    _restore();
    return ClockShape.circle;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_clockShapeKey);
    if (saved == null) return;
    final match = ClockShape.values.where((e) => e.name == saved);
    if (match.isNotEmpty) state = match.first;
  }

  Future<void> select(ClockShape shape) async {
    state = shape;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clockShapeKey, shape.name);
  }
}

final clockShapeProvider = NotifierProvider<ClockShapeNotifier, ClockShape>(ClockShapeNotifier.new);
