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

Future<double> _clockCenterX(WidgetTester tester, String quoteText) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        quoteProvider.overrideWith(() => _FixedQuoteNotifier(_quoteOfLength(quoteText))),
      ],
      child: const MaterialApp(home: MainScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return tester.getCenter(find.byType(ClockWidget)).dx;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('clock stays horizontally centered regardless of quote length', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final shortCenter = await _clockCenterX(tester, '짧다.');
    final longCenter = await _clockCenterX(
      tester,
      '이 문장은 아주 길게 늘어져서 여러 줄에 걸쳐 줄바꿈이 일어나도록 일부러 만든 아주 길고 긴 예문입니다. 정말 길게 계속 이어집니다.',
    );

    expect(longCenter, closeTo(shortCenter, 0.5));
    expect(shortCenter, closeTo(200.0, 0.5)); // 400-wide viewport, screen center
  });
}
