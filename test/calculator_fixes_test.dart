import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'support/calculator_test_helpers.dart';

import 'package:sheperd_app3/meal_history.dart';
import 'package:sheperd_app3/money.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    WidgetController.hitTestWarningShouldBeFatal = true;
  });

  test('decimal multiplication rounds half cents up exactly', () {
    expect(ingredientCents('1', '1.005'), BigInt.from(101));
    expect(ingredientCents('3', '0.335'), BigInt.from(101));
    expect(ingredientCents('0.1', '0.2'), BigInt.from(2));
    expect(ingredientCents('1', '0.0049'), BigInt.zero);
    expect(ingredientCents('.5', '0.01'), BigInt.one);
    expect(
      formatMoney(ingredientCents('999999999999', '999999999999')),
      '\$999999999998000000000001.00',
    );
    expect(servingCents(BigInt.from(1), 2), BigInt.one);
    expect(servingCents(BigInt.from(100), 3), BigInt.from(33));
  });

  test('invalid numbers never become valid zero costs', () {
    for (final value in [
      '',
      '-1',
      'NaN',
      'Infinity',
      '1e3',
      '1/2',
      '1,5',
      '\$2',
      '0.1234567',
      '1000000000000',
    ]) {
      expect(decimalError(value, positive: false), isNotNull, reason: value);
    }
    expect(decimalError('0', positive: false), isNull);
    expect(decimalError('0', positive: true), isNotNull);
    expect(decimalError(' 2.5 ', positive: true), isNull);
    for (final value in ['', '0', '-1', '2.5', 'NaN', '1000000']) {
      expect(parseServings(value), isNull, reason: value);
    }
    expect(parseServings('4'), 4);
  });

  test('legacy snapshots remain readable and new cents stay exact', () {
    final legacy = SavedIngredient.fromJson({
      'name': 'Rice',
      'quantity': '1',
      'unit': 'unit',
      'price': '.335',
      'cost': .335,
    });
    expect(legacy.cents, BigInt.from(34));
    final large = ingredientCents('999999999999', '999999999999');
    final saved = SavedIngredient(
      name: 'Bulk',
      quantity: '999999999999',
      unit: 'unit',
      price: '999999999999',
      cost: large.toDouble() / 100,
      preciseCents: large,
    );
    expect(SavedIngredient.fromJson(saved.toJson()).cents, large);
  });

  testWidgets('deleting first row preserves remaining text and unit values', (
    tester,
  ) async {
    await start(tester);
    await enter(tester, 'Ingredient', 'Rice');
    await enter(tester, 'Ingredient', 'Beans', row: 1);
    await enter(tester, 'Qty', '2', row: 1);
    await enter(tester, 'Price/unit', '3', row: 1);
    await tap(tester, find.byType(DropdownButtonFormField<String>).at(1));
    await tester.tap(find.text('kg').last);
    await tester.pumpAndSettle();
    await tap(tester, find.byTooltip('Remove ingredient').first);
    expect(textAt(tester, 'Ingredient', 0), 'Beans');
    expect(textAt(tester, 'Qty', 0), '2');
    expect(textAt(tester, 'Price/unit', 0), '3');
    expect(find.text('kg'), findsOneWidget);
    await enter(tester, 'Qty', '4');
    expect(find.text('\$12.00'), findsWidgets);
    await tap(tester, find.byTooltip('Remove ingredient').last);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == 'Remove ingredient',
            ),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('reset clears rendered inputs and units, then accepts new data', (
    tester,
  ) async {
    await start(tester);
    await enter(tester, 'Meal name', 'Dinner');
    await enter(tester, 'Servings', '8');
    await enter(tester, 'Ingredient', 'Rice');
    await enter(tester, 'Qty', '2');
    await enter(tester, 'Price/unit', '3');
    await tap(tester, find.byType(DropdownButtonFormField<String>).first);
    await tester.tap(find.text('kg').last);
    await tester.pumpAndSettle();
    await tap(tester, find.text('Reset'));
    await tester.ensureVisible(field('Meal name'));
    expect(textAt(tester, 'Meal name', 0), '');
    expect(textAt(tester, 'Servings', 0), '4');
    for (var i = 0; i < 3; i++) {
      expect(textAt(tester, 'Ingredient', i), '');
      expect(textAt(tester, 'Qty', i), '');
      expect(textAt(tester, 'Price/unit', i), '');
    }
    expect(find.text('kg'), findsNothing);
    await enter(tester, 'Ingredient', 'Soup');
    await enter(tester, 'Qty', '1');
    await enter(tester, 'Price/unit', '5');
    expect(find.text('\$5.00'), findsWidgets);
  });

  testWidgets(
    'unnamed rows are excluded consistently from totals, shopping and history',
    (tester) async {
      await start(tester);
      await enter(tester, 'Qty', '2');
      await enter(tester, 'Price/unit', '50');
      await enter(tester, 'Ingredient', 'Beans', row: 1);
      await enter(tester, 'Qty', '1', row: 1);
      await enter(tester, 'Price/unit', '3', row: 1);
      expect(find.text('Unnamed: excluded from totals'), findsOneWidget);
      await tester.ensureVisible(find.text('Total meal cost'));
      expect(summary(tester, 'Total meal cost'), '\$3.00');
      expect(summary(tester, 'Ingredients'), '1');
      await tap(tester, find.text('Shopping List'));
      expect(find.byType(CheckboxListTile), findsOneWidget);
      expect(summary(tester, 'Remaining cost'), '\$3.00');
      await tap(tester, find.text('Calculator'));
      await tap(tester, find.text('Save meal'), scrollDelta: -400);
      final meal = (await MealHistoryRepository().load()).single;
      expect(meal.ingredients.single.name, 'Beans');
      expect(meal.totalCents, BigInt.from(300));
    },
  );

  testWidgets('invalid inputs show errors, suppress totals and block saving', (
    tester,
  ) async {
    await start(tester);
    await enter(tester, 'Ingredient', 'Rice');
    await enter(tester, 'Qty', 'NaN');
    await enter(tester, 'Price/unit', '-1');
    await enter(tester, 'Servings', '0');
    expect(find.text('Enter a whole number from 1 to 999999.'), findsOneWidget);
    expect(find.textContaining('Enter a number'), findsNWidgets(2));
    await tester.ensureVisible(find.text('Total meal cost'));
    expect(summary(tester, 'Total meal cost'), 'Check inputs');
    expect(summary(tester, 'Cost / serving'), 'Check inputs');
    await tap(tester, find.text('Save meal'), scrollDelta: -400);
    expect(await MealHistoryRepository().load(), isEmpty);
    await enter(tester, 'Qty', '1');
    await enter(tester, 'Price/unit', '0');
    await enter(tester, 'Servings', '2');
    await tap(tester, find.text('Save meal'), scrollDelta: -400);
    expect(
      (await MealHistoryRepository().load()).single.totalCents,
      BigInt.zero,
    );
  });

  testWidgets(
    'rounded row costs reconcile with total, cart and saved history',
    (tester) async {
      await start(tester);
      for (var i = 0; i < 2; i++) {
        await enter(tester, 'Ingredient', 'Item $i', row: i);
        await enter(tester, 'Qty', '1', row: i);
        await enter(tester, 'Price/unit', '.335', row: i);
      }
      await tester.ensureVisible(find.text('Total meal cost'));
      expect(summary(tester, 'Total meal cost'), '\$0.68');
      expect(summary(tester, 'Cost / serving'), '\$0.17');
      await tap(tester, find.text('Shopping List'));
      expect(summary(tester, 'Remaining cost'), '\$0.68');
      await tap(tester, find.byType(CheckboxListTile).first);
      expect(summary(tester, 'Remaining cost'), '\$0.34');
      await tap(tester, find.text('Calculator'));
      await tap(tester, find.text('Save meal'), scrollDelta: -400);
      final meal = (await MealHistoryRepository().load()).single;
      expect(meal.totalCents, BigInt.from(68));
      expect(meal.perServingCents, BigInt.from(17));
    },
  );

  for (final (width, scale) in [(320.0, 1.0), (390.0, 2.0), (768.0, 1.0)]) {
    testWidgets(
      'calculator and shopping fit width $width at text scale $scale',
      (tester) async {
        await start(tester, width: width, scale: scale);
        await enter(tester, 'Ingredient', 'Rice');
        await enter(tester, 'Qty', '2');
        await enter(tester, 'Price/unit', '3.25');
        await tap(tester, find.text('Shopping List'));
        expect(find.byType(CheckboxListTile), findsOneWidget);
        await tap(tester, find.text('Calculator'));
        await tap(tester, find.text('Reset'));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('large exact amounts fit narrow shopping and history views', (
    tester,
  ) async {
    await start(tester, width: 320);
    await enter(tester, 'Ingredient', 'Bulk');
    await enter(tester, 'Qty', '999999999999');
    await enter(tester, 'Price/unit', '999999999999');
    await tap(tester, find.text('Shopping List'));
    expect(tester.takeException(), isNull);
    await tap(tester, find.text('Calculator'));
    await tap(tester, find.text('Save meal'), scrollDelta: -400);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tap(tester, find.text('Previous Meals'));
    await tap(tester, find.text('Untitled meal'));
    expect(find.text('Bulk'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resizing preserves text fields and selected units', (
    tester,
  ) async {
    await start(tester);
    await enter(tester, 'Ingredient', 'Rice');
    await enter(tester, 'Qty', '2');
    await enter(tester, 'Price/unit', '3');
    await tap(tester, find.byType(DropdownButtonFormField<String>).first);
    await tester.tap(find.text('kg').last);
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(390, 1200);
    await tester.pumpAndSettle();
    expect(textAt(tester, 'Ingredient', 0), 'Rice');
    expect(textAt(tester, 'Qty', 0), '2');
    tester.view.physicalSize = const Size(1200, 1200);
    await tester.pumpAndSettle();
    expect(textAt(tester, 'Price/unit', 0), '3');
    expect(find.text('kg'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
