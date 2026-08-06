import 'package:home_widget/home_widget.dart';

import '../model/quote.dart';

/// Pushes the current quote to the Android home-screen widgets.
///
/// The clock part of each widget is a native `TextClock`, which keeps
/// itself accurate with no help from Flutter. Only the quote text changes
/// content (not just time), so that's the one thing this service needs to
/// push — [SmallWidgetProvider] doesn't even read it back.
class WidgetSyncService {
  static const _androidProviders = [
    'SmallWidgetProvider',
    'MediumWidgetProvider',
    'LargeWidgetProvider',
  ];

  Future<void> syncQuote(Quote quote) async {
    await HomeWidget.saveWidgetData<String>('widget_quote', '"${quote.text}"');
    await HomeWidget.saveWidgetData<String>('widget_attribution', quote.attribution ?? '');
    for (final name in _androidProviders) {
      await HomeWidget.updateWidget(androidName: name);
    }
  }
}
