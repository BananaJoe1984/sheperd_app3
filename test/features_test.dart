import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sheperd_app3/main.dart' as app;
import 'package:sheperd_app3/meal_history.dart';

import 'support/calculator_test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    WidgetController.hitTestWarningShouldBeFatal = true;
  });

  testWidgets('app entry point opens calculator with default meal and tabs', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();
    expect(find.text('Grocery Meal Cost Calculator'), findsOneWidget);
    expect(textAt(tester, 'Meal name', 0), '');
    expect(textAt(tester, 'Servings', 0), '4');
    expect(field('Ingredient'), findsNWidgets(3));
    expect(find.text('Calculator'), findsOneWidget);
    expect(find.text('Shopping List'), findsOneWidget);
    expect(find.text('Previous Meals'), findsOneWidget);
    expect(Theme.of(tester.element(field('Meal name'))).useMaterial3, isTrue);
  });

  testWidgets(
    'add ingredient participates in totals and shopping, then remove it',
    (tester) async {
      await start(tester);
      await tap(tester, find.text('Add ingredient'));
      expect(field('Ingredient'), findsNWidgets(4));
      await enter(tester, 'Ingredient', 'Apples', row: 3);
      await enter(tester, 'Qty', '3', row: 3);
      await enter(tester, 'Price/unit', '2', row: 3);
      await tester.ensureVisible(find.text('Total meal cost'));
      expect(summary(tester, 'Total meal cost'), '\$6.00');
      expect(summary(tester, 'Cost / serving'), '\$1.50');
      await tap(tester, find.text('Shopping List'));
      expect(find.text('Apples'), findsOneWidget);
      await tap(tester, find.text('Calculator'));
      await tap(tester, find.byTooltip('Remove ingredient').last);
      expect(field('Ingredient'), findsNWidgets(3));
      await tap(tester, find.text('Shopping List'));
      expect(find.textContaining('Add named ingredients'), findsOneWidget);
    },
  );

  testWidgets(
    'all ten units appear in shopping and selected unit persists in history',
    (tester) async {
      await start(tester);
      await enter(tester, 'Ingredient', 'Flour');
      await enter(tester, 'Qty', '2');
      await enter(tester, 'Price/unit', '1.25');
      for (final unit in [
        'g',
        'kg',
        'ml',
        'l',
        'oz',
        'lb',
        'cup',
        'tbsp',
        'tsp',
        'unit',
      ]) {
        await tap(tester, find.byType(DropdownButtonFormField<String>).first);
        await tester.tap(find.text(unit).last);
        await tester.pumpAndSettle();
        await tap(tester, find.text('Shopping List'));
        expect(find.text('2 $unit'), findsOneWidget);
        expect(summary(tester, 'Remaining cost'), '\$2.50');
        await tap(tester, find.text('Calculator'));
      }
      await tap(tester, find.text('Save meal'), scrollDelta: -400);
      final meal = (await MealHistoryRepository().load()).single;
      expect(meal.ingredients.single.unit, 'unit');
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tap(tester, find.text('Previous Meals'));
      await tap(tester, find.text('Untitled meal'));
      expect(find.textContaining('2 unit'), findsOneWidget);
    },
  );

  testWidgets(
    'servings changes only per-serving cost and invalid servings block save',
    (tester) async {
      await start(tester);
      await enter(tester, 'Ingredient', 'Rice');
      await enter(tester, 'Qty', '2');
      await enter(tester, 'Price/unit', '4');
      await enter(tester, 'Servings', '8');
      await tester.ensureVisible(find.text('Total meal cost'));
      expect(summary(tester, 'Total meal cost'), '\$8.00');
      expect(summary(tester, 'Cost / serving'), '\$1.00');
      expect(textAt(tester, 'Qty', 0), '2');
      await enter(tester, 'Servings', '1.5');
      await tap(tester, find.text('Save meal'), scrollDelta: -400);
      expect(await MealHistoryRepository().load(), isEmpty);
      await enter(tester, 'Servings', '2');
      await tap(tester, find.text('Save meal'), scrollDelta: -400);
      expect((await MealHistoryRepository().load()).single.servings, 2);
    },
  );

  testWidgets(
    'check, uncheck and edit cart items; reset clears shopping state',
    (tester) async {
      await start(tester);
      await enter(tester, 'Ingredient', 'Rice');
      await enter(tester, 'Qty', '2');
      await enter(tester, 'Price/unit', '3');
      await tap(tester, find.text('Shopping List'));
      expect(summary(tester, 'In cart'), '0 / 1');
      await tap(tester, find.byType(CheckboxListTile));
      expect(summary(tester, 'In cart'), '1 / 1');
      expect(summary(tester, 'Remaining cost'), '\$0.00');
      expect(
        tester.widget<Text>(find.text('Rice')).style!.decoration,
        TextDecoration.lineThrough,
      );
      await tap(tester, find.text('Calculator'));
      await enter(tester, 'Price/unit', '4');
      await tester.ensureVisible(find.text('Total meal cost'));
      expect(summary(tester, 'Total meal cost'), '\$8.00');
      await tap(tester, find.text('Shopping List'));
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isTrue,
      );
      await tap(tester, find.byType(CheckboxListTile));
      expect(summary(tester, 'Remaining cost'), '\$8.00');
      expect(
        tester
                .widget<Text>(find.text('Rice'))
                .style!
                .decoration
                ?.contains(TextDecoration.lineThrough) ??
            false,
        isFalse,
      );
      await tap(tester, find.text('Calculator'));
      await tap(tester, find.text('Reset'));
      await tap(tester, find.text('Shopping List'));
      expect(find.textContaining('Add named ingredients'), findsOneWidget);
    },
  );

  testWidgets(
    'invalid shopping cost is visible until corrected or checked off',
    (tester) async {
      await start(tester);
      await enter(tester, 'Ingredient', 'Rice');
      await enter(tester, 'Qty', '1');
      await enter(tester, 'Price/unit', 'bad');
      await tap(tester, find.text('Shopping List'));
      expect(summary(tester, 'Remaining cost'), 'Check inputs');
      await tap(tester, find.byType(CheckboxListTile));
      expect(summary(tester, 'Remaining cost'), '\$0.00');
      await tap(tester, find.text('Calculator'));
      await enter(tester, 'Price/unit', '2');
      await tap(tester, find.text('Shopping List'));
      await tap(tester, find.byType(CheckboxListTile));
      expect(summary(tester, 'Remaining cost'), '\$2.00');
    },
  );

  testWidgets('multiple saves keep separate snapshots with newest meal first', (
    tester,
  ) async {
    await start(tester);
    await enter(tester, 'Meal name', ' First meal ');
    await enter(tester, 'Ingredient', 'Rice');
    await enter(tester, 'Qty', '1');
    await enter(tester, 'Price/unit', '2');
    await tap(tester, find.text('Save meal'), scrollDelta: -400);
    await enter(tester, 'Meal name', 'Second meal');
    await enter(tester, 'Price/unit', '5');
    await tap(tester, find.text('Save meal'), scrollDelta: -400);
    final meals = await MealHistoryRepository().load();
    expect(meals.map((m) => m.name), ['Second meal', 'First meal']);
    expect(meals.map((m) => m.totalCost), [5, 2]);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    await tap(tester, find.text('Previous Meals'));
    expect(
      tester.getTopLeft(find.text('Second meal')).dy,
      lessThan(tester.getTopLeft(find.text('First meal')).dy),
    );
    await tap(tester, find.text('First meal'));
    expect(find.text('\$0.50 per serving'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tap(tester, find.text('Calculator'));
    expect(textAt(tester, 'Meal name', 0), 'Second meal');
  });

  testWidgets('old unnamed ingredient snapshots remain viewable', (
    tester,
  ) async {
    await MealHistoryRepository().save([
      SavedMeal(
        name: 'Legacy meal',
        savedAt: DateTime.utc(2026, 9, 1),
        servings: 1,
        ingredients: const [
          SavedIngredient(
            name: '',
            quantity: '',
            unit: 'unit',
            price: '',
            cost: 0,
          ),
        ],
      ),
    ]);
    await start(tester);
    await tap(tester, find.text('Previous Meals'));
    await tap(tester, find.text('Legacy meal'));
    expect(find.text('Unnamed ingredient'), findsOneWidget);
    expect(find.textContaining('Price/unit: 0'), findsOneWidget);
  });
}
