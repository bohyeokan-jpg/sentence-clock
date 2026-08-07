import 'package:home_widget/home_widget.dart';

import '../model/alarm_config.dart';
import '../model/quote.dart';

/// Pushes the current quote and alarm time to the Android home-screen
/// widgets.
///
/// The clock itself needs no help from this service at all: the digital
/// time is a native `TextClock`, and the analog face next to it is a native
/// `AnalogClock` (custom dial/hour/minute drawables baked into the app at
/// build time — see res/drawable-xxxhdpi/widget_clock_*.png). Both tick on
/// their own, system-driven, exactly like a real clock widget should — an
/// earlier version rendered the analog face as a Flutter-drawn PNG instead,
/// but that only refreshed when the app was open to redraw it, so it went
/// visibly stale (frozen hands) whenever the app hadn't run in a while.
/// The red alarm hand overlaid on that same clock is a static image too
/// (AnalogClock has no third-hand slot), but it doesn't need to tick — it
/// just needs to be rotated to the right angle and shown/hidden, which
/// [AlarmHandView.kt] does natively from the values this pushes.
///
/// Only the quote's *content* and the alarm's *setting* change over time
/// rather than just ticking, so those are the two things that still need
/// pushing from here.
class WidgetSyncService {
  static const _androidProviders = [
    'SmallWidgetProvider',
    'MediumWidgetProvider',
    'LargeWidgetProvider',
  ];

  Future<void> syncQuote(Quote quote) async {
    await HomeWidget.saveWidgetData<String>('widget_quote', '"${quote.text}"');
    await HomeWidget.saveWidgetData<String>('widget_attribution', quote.attribution ?? '');
    await _updateAll();
  }

  Future<void> syncAlarm(AlarmConfig config) async {
    await HomeWidget.saveWidgetData<bool>('widget_alarm_enabled', config.enabled);
    await HomeWidget.saveWidgetData<int>('widget_alarm_hour', config.hour);
    await HomeWidget.saveWidgetData<int>('widget_alarm_minute', config.minute);
    await _updateAll();
  }

  Future<void> _updateAll() async {
    for (final name in _androidProviders) {
      await HomeWidget.updateWidget(androidName: name);
    }
  }
}
