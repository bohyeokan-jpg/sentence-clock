import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../model/app_theme.dart';
import '../model/clock_shape.dart';
import '../model/quote.dart';
import '../widget/analog_clock_painter.dart';

/// Pushes the current quote and a freshly-rendered clock face to the
/// Android home-screen widgets.
///
/// The digital time in each widget is a native `TextClock`, which keeps
/// itself accurate with no help from Flutter. The little square analog
/// face next to it can't be — RemoteViews has no custom-paint view, so it
/// has to be a plain image, rendered here (reusing the exact same painter
/// the in-app clock uses, forced to the square shape so it fills a
/// rectangular widget tile cleanly) and pushed as a PNG file path via
/// `home_widget`'s renderFlutterWidget. It only refreshes when the app is
/// alive to render it (same minute-tick as the quote), so it can go stale
/// if the app hasn't been opened in a while — the TextClock next to it
/// stays accurate regardless.
class WidgetSyncService {
  static const _androidProviders = [
    'SmallWidgetProvider',
    'MediumWidgetProvider',
    'LargeWidgetProvider',
  ];

  static const _clockImageSize = 160.0;

  Future<void> sync(Quote quote) async {
    await HomeWidget.saveWidgetData<String>('widget_quote', '"${quote.text}"');
    await HomeWidget.saveWidgetData<String>('widget_attribution', quote.attribution ?? '');
    await HomeWidget.renderFlutterWidget(
      _ClockFace(size: _clockImageSize),
      key: 'widget_clock_image',
      logicalSize: const Size(_clockImageSize, _clockImageSize),
      pixelRatio: 2.5,
    );
    for (final name in _androidProviders) {
      await HomeWidget.updateWidget(androidName: name);
    }
  }
}

/// Matches widget_background.xml's solid card color exactly.
const _widgetCardColor = Color(0xFFF6F1E7);

/// The widget always renders on its own fixed cream card background, so the
/// clock face uses the cream palette regardless of the in-app theme —
/// otherwise a dark-themed face could go muddy against the card.
///
/// renderFlutterWidget captures a plain (alpha-channel) PNG, and the square
/// clock's corners fall outside its rounded-rect shape — left unpainted,
/// they'd be fully transparent in that PNG, letting whatever is behind the
/// widget's ImageView show through at the corners. Filling the whole canvas
/// with the card color first (ColoredBox, not just the painter's own fill)
/// makes every pixel opaque, corners included.
class _ClockFace extends StatelessWidget {
  final double size;
  const _ClockFace({required this.size});

  @override
  Widget build(BuildContext context) {
    final palette = appThemePalettes[AppThemeId.cream]!;
    return ColoredBox(
      color: _widgetCardColor,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: AnalogClockPainter(
            time: DateTime.now(),
            ink: palette.ink,
            accent: palette.accent,
            faceFill: palette.clockFace,
            shape: ClockShape.square,
          ),
        ),
      ),
    );
  }
}
