import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A value snapshot, independent of the calculator's mutable input fields.
class SavedIngredient {
  const SavedIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.cost,
  });

  final String name;
  final String quantity;
  final String unit;
  final String price;
  final double cost;

  Map<String, Object> toJson() => {
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'price': price,
    'cost': cost,
  };

  factory SavedIngredient.fromJson(Map<String, dynamic> json) {
    final cost = (json['cost'] as num).toDouble();
    if (!cost.isFinite || cost < 0) throw const FormatException('Invalid cost');
    return SavedIngredient(
      name: json['name'] as String,
      quantity: json['quantity'] as String,
      unit: json['unit'] as String,
      price: json['price'] as String,
      cost: cost,
    );
  }
}

class SavedMeal {
  SavedMeal({
    required this.name,
    required this.savedAt,
    required this.servings,
    required List<SavedIngredient> ingredients,
  }) : ingredients = List.unmodifiable(ingredients);

  final String name;
  final DateTime savedAt;
  final int servings;
  final List<SavedIngredient> ingredients;

  double get totalCost => ingredients.fold(0, (sum, item) => sum + item.cost);
  double get costPerServing => totalCost / servings;

  Map<String, Object> toJson() => {
    'name': name,
    'savedAt': savedAt.toUtc().toIso8601String(),
    'servings': servings,
    'ingredients': ingredients.map((i) => i.toJson()).toList(),
  };

  factory SavedMeal.fromJson(Map<String, dynamic> json) {
    final servings = json['servings'] as int;
    if (servings < 1) throw const FormatException('Invalid servings');
    return SavedMeal(
      name: json['name'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
      servings: servings,
      ingredients: (json['ingredients'] as List)
          .map((i) => SavedIngredient.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MealHistoryRepository {
  MealHistoryRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const storageKey = 'meal_history_v1';
  final SharedPreferencesAsync _preferences;

  Future<List<SavedMeal>> load() async {
    final raw = await _preferences.getString(storageKey);
    if (raw == null) return [];
    final document = jsonDecode(raw) as Map<String, dynamic>;
    if (document['version'] != 1) {
      throw const FormatException('Unsupported meal history version');
    }
    final meals = (document['meals'] as List)
        .map((m) => SavedMeal.fromJson(m as Map<String, dynamic>))
        .toList();
    meals.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return meals;
  }

  Future<void> save(List<SavedMeal> meals) => _preferences.setString(
    storageKey,
    jsonEncode({'version': 1, 'meals': meals.map((m) => m.toJson()).toList()}),
  );
}
