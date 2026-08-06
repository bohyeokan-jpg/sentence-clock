import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:munjang_sigye/model/quote.dart';
import 'package:munjang_sigye/view/main_screen.dart';
import 'package:munjang_sigye/viewmodel/quote_provider.dart';
import 'package:munjang_sigye/widget/clock_widget.dart';

class _FixedQuoteNotifier extends QuoteNotifier {
  final QuoteState fixed;
  _FixedQuoteNotifier(this.fixed);

  @override
  Future<QuoteState> build() async => fixed;
}

QuoteState _quoteOfLength(String text) =>
    QuoteState(category: 'MORNING', quote: Quote(text: text, book: '', author: ''));

const _shortQuote = '짧다.';
const _longQuote =
    '이 문장은 아주 길게 늘어져서 여러 줄에 걸쳐 줄바꿈이 일어나도록 일부러 만든 아주 길고 긴 예문입니다. 정말 길게 계속 이어집니다.';

class _Layout {
  final Offset clockCenter;
  final Offset footerCenter;
  _Layout(this.clockCenter, this.footerCenter);
}

Future<_Layout> _pumpAndMeasure(WidgetTester tester, String quoteText) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        quoteProvider.overrideWith(() => _FixedQuoteNotifier(_quoteOfLength(quoteText))),
      ],
      child: const MaterialApp(home: MainScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return _Layout(
    tester.getCenter(find.byType(ClockWidget)),
    tester.getCenter(find.text('1분마다 새 문장')),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('clock and footer stay put regardless of quote length; the quote shrinks instead',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final short = await _pumpAndMeasure(tester, _shortQuote);
    final long = await _pumpAndMeasure(tester, _longQuote);

    expect(long.clockCenter.dx, closeTo(short.clockCenter.dx, 0.5));
    expect(long.clockCenter.dy, closeTo(short.clockCenter.dy, 0.5));
    expect(short.clockCenter.dx, closeTo(200.0, 0.5)); // 400-wide viewport, screen center

    expect(long.footerCenter.dx, closeTo(short.footerCenter.dx, 0.5));
    expect(long.footerCenter.dy, closeTo(short.footerCenter.dy, 0.5));
  });
}
