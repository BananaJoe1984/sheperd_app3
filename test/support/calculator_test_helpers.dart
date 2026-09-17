import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheperd_app3/meal_cost_calculator_screen.dart';

Finder field(String label) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText == label,
);

Future<void> start(
  WidgetTester tester, {
  double width = 1200,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: const MealCostCalculatorScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> enter(
  WidgetTester tester,
  String label,
  String value, {
  int row = 0,
}) async {
  final target = field(label).at(row);
  await tester.ensureVisible(target);
  await tester.enterText(target, value);
  await tester.pumpAndSettle();
}

Future<void> tap(
  WidgetTester tester,
  Finder target, {
  double scrollDelta = 400,
}) async {
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      scrollDelta,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

String textAt(WidgetTester tester, String label, int row) =>
    tester.widget<TextField>(field(label).at(row)).controller!.text;

String summary(WidgetTester tester, String label) {
  final column = find
      .ancestor(of: find.text(label).last, matching: find.byType(Column))
      .first;
  return tester
      .widgetList<Text>(
        find.descendant(of: column, matching: find.byType(Text)),
      )
      .first
      .data!;
}
