import 'package:flutter/material.dart';

const List<String> _unitOptions = [
  'unit',
  'g',
  'kg',
  'ml',
  'l',
  'oz',
  'lb',
  'cup',
  'tbsp',
  'tsp',
];

class Ingredient {
  Ingredient({this.name = '', this.quantity = '', this.unit = 'unit', this.price = ''});

  String name;
  String quantity;
  String unit;
  String price;

  double get cost {
    final qty = double.tryParse(quantity) ?? 0;
    final pricePerUnit = double.tryParse(price) ?? 0;
    return qty * pricePerUnit;
  }
}

class MealCostCalculatorScreen extends StatefulWidget {
  const MealCostCalculatorScreen({super.key});

  @override
  State<MealCostCalculatorScreen> createState() => _MealCostCalculatorScreenState();
}

class _MealCostCalculatorScreenState extends State<MealCostCalculatorScreen> {
  final TextEditingController _mealNameController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController(text: '4');

  final List<Ingredient> _ingredients = [Ingredient(), Ingredient(), Ingredient()];

  double get _totalCost => _ingredients.fold(0, (sum, ing) => sum + ing.cost);

  int get _servings {
    final value = int.tryParse(_servingsController.text) ?? 1;
    return value < 1 ? 1 : value;
  }

  double get _costPerServing => _totalCost / _servings;

  int get _ingredientCount => _ingredients.where((ing) => ing.name.trim().isNotEmpty).length;

  void _addIngredient() {
    setState(() => _ingredients.add(Ingredient()));
  }

  void _removeIngredient(int index) {
    setState(() => _ingredients.removeAt(index));
  }

  void _resetAll() {
    setState(() {
      _mealNameController.clear();
      _servingsController.text = '4';
      _ingredients
        ..clear()
        ..addAll([Ingredient(), Ingredient(), Ingredient()]);
    });
  }

  @override
  void dispose() {
    _mealNameController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = (double v) => '\$${v.toStringAsFixed(2)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery Meal Cost Calculator'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _mealNameController,
                        decoration: const InputDecoration(
                          labelText: 'Meal name',
                          hintText: 'e.g. Chicken Stir Fry',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _servingsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Servings',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < _ingredients.length; i++) ...[
                      _IngredientRow(
                        ingredient: _ingredients[i],
                        onChanged: () => setState(() {}),
                        onRemove: () => _removeIngredient(i),
                      ),
                      const Divider(height: 24),
                    ],
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _addIngredient,
                        icon: const Icon(Icons.add),
                        label: const Text('Add ingredient'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _SummaryItem(label: 'Total meal cost', value: currency(_totalCost)),
                        _SummaryItem(label: 'Cost per serving', value: currency(_costPerServing)),
                        _SummaryItem(label: 'Ingredients', value: '$_ingredientCount'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: _resetAll, child: const Text('Reset')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.ingredient,
    required this.onChanged,
    required this.onRemove,
  });

  final Ingredient ingredient;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            initialValue: ingredient.name,
            decoration: const InputDecoration(labelText: 'Ingredient', isDense: true),
            onChanged: (v) {
              ingredient.name = v;
              onChanged();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextFormField(
            initialValue: ingredient.quantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Qty', isDense: true),
            onChanged: (v) {
              ingredient.quantity = v;
              onChanged();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            initialValue: ingredient.unit,
            decoration: const InputDecoration(labelText: 'Unit', isDense: true),
            items: _unitOptions
                .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                .toList(),
            onChanged: (v) {
              ingredient.unit = v ?? 'unit';
              onChanged();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextFormField(
            initialValue: ingredient.price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Price/unit', isDense: true),
            onChanged: (v) {
              ingredient.price = v;
              onChanged();
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 64,
          child: Text(
            '\$${ingredient.cost.toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          tooltip: 'Remove ingredient',
          onPressed: onRemove,
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
