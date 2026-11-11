import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:buzz_calculator/main.dart';

void main() {
  Future<void> tapButton(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> enterExpression(WidgetTester tester, String expression) async {
    for (final character in expression.split('')) {
      await tapButton(tester, character);
    }
  }

  testWidgets('evaluates trigonometry in degrees and radians', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tapButton(tester, 'sin');
    await enterExpression(tester, '90)');
    await tapButton(tester, '=');
    expect(find.text('1'), findsNWidgets(2));

    await tapButton(tester, 'c');
    await tapButton(tester, 'cos');
    await enterExpression(tester, '60)');
    await tapButton(tester, '=');
    expect(find.text('0.5'), findsOneWidget);

    await tapButton(tester, 'c');
    await tapButton(tester, 'tan');
    await enterExpression(tester, '45)');
    await tapButton(tester, '=');
    expect(find.text('1'), findsNWidgets(2));

    await tapButton(tester, 'c');
    await tapButton(tester, 'DEG');
    await tapButton(tester, 'sin');
    await enterExpression(tester, '1)');
    await tapButton(tester, '=');
    expect(find.text('0.841470984808'), findsOneWidget);

    await tapButton(tester, 'c');
    await tapButton(tester, 'cos');
    await enterExpression(tester, '1)');
    await tapButton(tester, '=');
    expect(find.text('0.540302305868'), findsOneWidget);

    await tapButton(tester, 'c');
    await tapButton(tester, 'tan');
    await enterExpression(tester, '1)');
    await tapButton(tester, '=');
    expect(find.text('1.55740772465'), findsOneWidget);

    await tapButton(tester, 'c');
    await tapButton(tester, 'RAD');
    await tapButton(tester, 'tan');
    await enterExpression(tester, '90)');
    await tapButton(tester, '=');
    expect(find.text('Error'), findsOneWidget);
  });

  testWidgets('translates the calculated answer into words', (tester) async {
    await tester.pumpWidget(const MyApp());
    await enterExpression(tester, '12+13');
    await tapButton(tester, '=');
    await tester.tap(find.byIcon(Icons.translate));
    await tester.pumpAndSettle();

    expect(find.text('Twenty-five'), findsOneWidget);
  });

  testWidgets('keeps long expressions horizontally scrollable', (tester) async {
    await tester.pumpWidget(const MyApp());
    await enterExpression(tester, '12345678901234567890123');

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      ),
      findsNWidgets(2),
    );
    expect(tester.takeException(), isNull);
  });
}
