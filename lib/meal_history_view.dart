import 'package:flutter/material.dart';

import 'meal_history.dart';
import 'money.dart';

class MealHistoryView extends StatelessWidget {
  const MealHistoryView({
    super.key,
    required this.meals,
    required this.loading,
    required this.hasError,
    required this.onRetry,
  });

  final List<SavedMeal> meals;
  final bool loading;
  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Could not load previous meals. Your saved data has not been changed.',
              ),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (meals.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No saved meals yet. Use Save meal in the Calculator tab.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: meals.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final meal = meals[index];
        final date = MaterialLocalizations.of(context)
            .formatMediumDate(meal.savedAt.toLocal());
        return Card(
          child: ListTile(
            title: Text(meal.name),
            subtitle: Text(
              '$date • ${meal.servings} servings\n'
              '${formatMoney(meal.totalCents)} total • '
              '${formatMoney(meal.perServingCents)} / serving',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => _MealDetail(meal: meal)),
            ),
          ),
        );
      },
    );
  }
}

class _MealDetail extends StatelessWidget {
  const _MealDetail({required this.meal});
  final SavedMeal meal;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(meal.name)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Saved ${MaterialLocalizations.of(context).formatFullDate(meal.savedAt.toLocal())}',
        ),
        const SizedBox(height: 12),
        Text(
          '${meal.servings} servings • ${formatMoney(meal.totalCents)} total',
        ),
        Text('${formatMoney(meal.perServingCents)} per serving'),
        const SizedBox(height: 16),
        for (final ingredient in meal.ingredients)
          Card(
            child: ListTile(
              title: Text(
                ingredient.name.trim().isEmpty
                    ? 'Unnamed ingredient'
                    : ingredient.name,
              ),
              subtitle: Text(
                '${ingredient.quantity} ${ingredient.unit} • '
                'Price/unit: ${ingredient.price.isEmpty ? "0" : ingredient.price}\n'
                '${formatMoney(ingredient.cents)}',
              ),
            ),
          ),
      ],
    ),
  );
}
