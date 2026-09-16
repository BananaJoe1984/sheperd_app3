import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sheperd_app3/meal_cost_calculator_screen.dart';
import 'package:sheperd_app3/meal_history.dart';

final class TestStorage extends InMemorySharedPreferencesAsync {
  TestStorage() : super.empty();
  bool failRead = false;
  bool failWrite = false;
  Completer<void>? writeGate;

  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) {
    if (failRead) throw StateError('Read failed');
    return super.getString(key, options);
  }

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async {
    if (failWrite) throw StateError('Write failed');
    await writeGate?.future;
    return super.setString(key, value, options);
  }
}

SavedMeal example({String name = 'Rice bowl', int day = 1}) => SavedMeal(
  name: name,
  savedAt: DateTime.utc(2026, 9, day),
  servings: 4,
  ingredients: const [
    SavedIngredient(
      name: 'Rice',
      quantity: '2',
      unit: 'cup',
      price: '1.50',
      cost: 3,
    ),
  ],
);

Finder field(String label) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText == label,
);

Future<void> openApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const MaterialApp(home: MealCostCalculatorScreen()));
  await tester.pumpAndSettle();
}

Future<void> enterMeal(WidgetTester tester, {String name = 'Rice bowl'}) async {
  await tester.enterText(field('Meal name'), name);
  await tester.enterText(field('Ingredient').first, 'Rice');
  await tester.enterText(field('Qty').first, '2');
  await tester.enterText(field('Price/unit').first, '1.50');
  await tester.pump();
}

void main() {
  late TestStorage storage;
  setUp(() {
    storage = TestStorage();
    SharedPreferencesAsyncPlatform.instance = storage;
  });

  test('new storage has no history', () async {
    expect(await MealHistoryRepository().load(), isEmpty);
  });

  test(
    'snapshots round trip through new repository and preferences instances',
    () async {
      await MealHistoryRepository().save([
        example(),
        example(name: 'Soup', day: 2),
      ]);
      final meals = await MealHistoryRepository().load();
      expect(meals.map((m) => m.name), ['Soup', 'Rice bowl']);
      expect(meals.last.toJson(), example().toJson());
      expect(meals.last.totalCost, 3);
      expect(meals.last.costPerServing, 0.75);
    },
  );

  test('snapshot owns an immutable copy of the ingredient list', () {
    final ingredients = example().ingredients.toList();
    final meal = SavedMeal(
      name: 'Meal',
      savedAt: DateTime.now(),
      servings: 2,
      ingredients: ingredients,
    );
    ingredients.clear();
    expect(meal.ingredients, hasLength(1));
    expect(() => meal.ingredients.clear(), throwsUnsupportedError);
  });

  test('corrupt and unsupported history is not silently discarded', () async {
    for (final raw in ['not json', '{"version":2,"meals":[]}']) {
      await SharedPreferencesAsync().setString(
        MealHistoryRepository.storageKey,
        raw,
      );
      await expectLater(
        MealHistoryRepository().load(),
        throwsA(isA<FormatException>()),
      );
      expect(
        await SharedPreferencesAsync().getString(
          MealHistoryRepository.storageKey,
        ),
        raw,
      );
    }
  });

  test('invalid stored servings and non-finite costs are rejected', () {
    expect(
      () => SavedMeal.fromJson({...example().toJson(), 'servings': 0}),
      throwsFormatException,
    );
    expect(
      () => SavedIngredient.fromJson({
        ...example().ingredients.first.toJson(),
        'cost': double.infinity,
      }),
      throwsFormatException,
    );
  });

  test('failed write preserves the previous saved document', () async {
    await MealHistoryRepository().save([example()]);
    storage.failWrite = true;
    await expectLater(
      MealHistoryRepository().save([example(name: 'Soup')]),
      throwsStateError,
    );
    expect((await MealHistoryRepository().load()).single.name, 'Rice bowl');
  });

  testWidgets('empty history explains how to save', (tester) async {
    await openApp(tester);
    await tester.tap(find.text('Previous Meals'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No saved meals yet'), findsOneWidget);
  });

  testWidgets('save, edit, reset, recreate app and inspect original snapshot', (
    tester,
  ) async {
    await openApp(tester);
    await enterMeal(tester);
    await tester.tap(find.text('Save meal'));
    await tester.pumpAndSettle();
    expect(find.text('Meal saved on this device.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.enterText(field('Ingredient').first, 'Changed');
    await tester.enterText(field('Price/unit').first, '99');
    await tester.ensureVisible(find.text('Reset'));
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      const MaterialApp(home: MealCostCalculatorScreen()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Previous Meals'));
    await tester.pumpAndSettle();
    expect(find.text('Rice bowl'), findsOneWidget);
    expect(find.textContaining('\$3.00 total'), findsOneWidget);
    await tester.tap(find.text('Rice bowl'));
    await tester.pumpAndSettle();
    expect(find.text('Rice'), findsOneWidget);
    expect(find.text('Changed'), findsNothing);
    expect(find.textContaining('Price/unit: 1.50'), findsOneWidget);
    expect(find.text('\$0.75 per serving'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'requires a named ingredient and supplies an untitled meal name',
    (tester) async {
      await openApp(tester);
      await tester.tap(find.text('Save meal'));
      await tester.pumpAndSettle();
      expect(
        find.text('Add at least one named ingredient before saving.'),
        findsOneWidget,
      );
      expect(await MealHistoryRepository().load(), isEmpty);
      await enterMeal(tester, name: ' ');
      await tester.tap(find.text('Save meal'));
      await tester.pumpAndSettle();
      expect(
        (await MealHistoryRepository().load()).single.name,
        'Untitled meal',
      );
    },
  );

  testWidgets('load failure disables saving and supports retry', (
    tester,
  ) async {
    await MealHistoryRepository().save([example()]);
    storage.failRead = true;
    await openApp(tester);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save meal'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Previous Meals'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Could not load previous meals'),
      findsOneWidget,
    );
    storage.failRead = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Rice bowl'), findsOneWidget);
  });

  testWidgets('save failure reports error and can be retried', (tester) async {
    await openApp(tester);
    await enterMeal(tester);
    storage.failWrite = true;
    await tester.tap(find.text('Save meal'));
    await tester.pumpAndSettle();
    expect(find.text('Could not save meal. Please try again.'), findsOneWidget);
    expect(await MealHistoryRepository().load(), isEmpty);
    storage.failWrite = false;
    await tester.tap(find.text('Save meal'));
    await tester.pumpAndSettle();
    expect(await MealHistoryRepository().load(), hasLength(1));
  });

  testWidgets('save remains disabled while a write is pending', (tester) async {
    await openApp(tester);
    await enterMeal(tester);
    storage.writeGate = Completer<void>();
    await tester.tap(find.text('Save meal'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Saving...'))
          .onPressed,
      isNull,
    );
    storage.writeGate!.complete();
    await tester.pumpAndSettle();
    expect(await MealHistoryRepository().load(), hasLength(1));
  });
}
