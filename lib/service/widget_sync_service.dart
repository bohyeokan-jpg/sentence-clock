import 'package:home_widget/home_widget.dart';

import '../model/quote.dart';

/// Pushes the current quote to the Android home-screen widgets.
///
/// The clock itself needs no help from this service at all: the digital
/// time is a native `TextClock`, and the analog face next to it is a native
/// `AnalogClock` (custom dial/hour/minute drawables baked into the app at
/// build time — see res/drawable-xxxhdpi/widget_clock_*.png). Both tick on
/// their own, system-driven, exactly like a real clock widget should — an
/// earlier version rendered the analog face as a Flutter-drawn PNG instead,
/// but that only refreshed when the app was open to redraw it, so it went
/// visibly stale (frozen hands) whenever the app hadn't run in a while.
/// Only the quote's *content* changes over time rather than just ticking,
/// so that's the one thing that still needs pushing from here.
class WidgetSyncService {
  static const _androidProviders = [
    'SmallWidgetProvider',
    'MediumWidgetProvider',
    'LargeWidgetProvider',
  ];

  Future<void> sync(Quote quote) async {
    await HomeWidget.saveWidgetData<String>('widget_quote', '"${quote.text}"');
    await HomeWidget.saveWidgetData<String>('widget_attribution', quote.attribution ?? '');
    for (final name in _androidProviders) {
      await HomeWidget.updateWidget(androidName: name);
    }
  }
}
