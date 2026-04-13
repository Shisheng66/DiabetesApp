import 'package:flutter_test/flutter_test.dart';

import 'package:new_app/main.dart';

void main() {
  testWidgets('app renders login shell', (WidgetTester tester) async {
    await tester.pumpWidget(const DiabetesApp());
    await tester.pump();

    expect(find.text('糖尿病健康管家'), findsWidgets);
  });
}
