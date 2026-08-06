import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:munjang_sigye/main.dart';

void main() {
  testWidgets('App launches and shows the main screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MunjangSigyeApp()));
    await tester.pump();

    expect(find.byType(MunjangSigyeApp), findsOneWidget);
  });
}
