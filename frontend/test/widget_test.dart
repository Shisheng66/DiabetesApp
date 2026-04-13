import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_app/widgets/premium_health_ui.dart';

void main() {
  testWidgets('HealthPageBackground renders child content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HealthPageBackground(
            child: Center(child: Text('测试内容')),
          ),
        ),
      ),
    );

    expect(find.text('测试内容'), findsOneWidget);
    expect(find.byType(FrostPanel), findsNothing);
  });
}
