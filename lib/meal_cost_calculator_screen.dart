import 'package:flutter/material.dart';

import 'meal_history.dart';
import 'meal_history_view.dart';
import 'money.dart';

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
  Ingredient({
    this.name = '',
    this.quantity = '',
    this.unit = 'unit',
    this.price = '',
    this.inCart = false,
  });

  String name;
  String quantity;
  String unit;
  String price;
  bool inCart;

  bool get named => name.trim().isNotEmpty;
  bool get started =>
      named || quantity.trim().isNotEmpty || price.trim().isNotEmpty;
  String? get quantityError => decimalError(quantity, positive: true);
  String? get priceError => decimalError(price, positive: false);
  bool get valid => quantityError == null && priceError == null;
  BigInt get cents => valid ? ingredientCents(quantity, price) : BigInt.zero;
  double get cost => cents.toDouble() / 100;
}

class MealCostCalculatorScreen extends StatefulWidget {
  const MealCostCalculatorScreen({super.key, this.historyRepository});

  final MealHistoryRepository? historyRepository;

  @override
  State<MealCostCalculatorScreen> createState() =>
      _MealCostCalculatorScreenState();
}

class _MealCostCalculatorScreenState extends State<MealCostCalculatorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );
  late final MealHistoryRepository _historyRepository =
      widget.historyRepository ?? MealHistoryRepository();
  List<SavedMeal> _savedMeals = [];
  bool _historyLoading = true;
  bool _historyError = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _historyLoading = true;
      _historyError = false;
    });
    try {
      final meals = await _historyRepository.load();
      if (!mounted) return;
      setState(() {
        _savedMeals = meals;
        _historyLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _historyError = true;
        _historyLoading = false;
      });
    }
  }

  Future<void> _saveMeal() async {
    if (_saving || _historyLoading || _historyError) return;
    if (_namedIngredients.isEmpty) {
      _showMessage('Add at least one named ingredient before saving.');
      return;
    }
    if (_servings == null || !_validMeal) {
      _showMessage(
        'Correct the highlighted quantities, prices and servings before saving.',
      );
      return;
    }
    final meal = SavedMeal(
      name: _mealNameController.text.trim().isEmpty
          ? 'Untitled meal'
          : _mealNameController.text.trim(),
      savedAt: DateTime.now(),
      servings: _servings!,
      ingredients: _namedIngredients
          .map(
            (i) => SavedIngredient(
              name: i.name,
              quantity: i.quantity,
              unit: i.unit,
              price: i.price,
              cost: i.cost,
              preciseCents: i.cents,
            ),
          )
          .toList(),
    );
    final updated = [meal, ..._savedMeals];
    setState(() => _saving = true);
    try {
      await _historyRepository.save(updated);
      if (!mounted) return;
      setState(() => _savedMeals = updated);
      _showMessage('Meal saved on this device.');
    } catch (_) {
      if (mounted) _showMessage('Could not save meal. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  final TextEditingController _mealNameController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController(
    text: '4',
  );

  final List<Ingredient> _ingredients = [
    Ingredient(),
    Ingredient(),
    Ingredient(),
  ];

  BigInt get _totalCents =>
      _namedIngredients.fold(BigInt.zero, (sum, i) => sum + i.cents);
  int? get _servings => parseServings(_servingsController.text);
  bool get _validMeal => _namedIngredients.every((i) => i.valid);
  List<Ingredient> get _namedIngredients =>
      _ingredients.where((i) => i.named).toList();
  int get _ingredientCount => _namedIngredients.length;
  BigInt get _remainingCents => _namedIngredients
      .where((i) => !i.inCart)
      .fold(BigInt.zero, (sum, i) => sum + i.cents);
  bool get _validRemaining =>
      _namedIngredients.where((i) => !i.inCart).every((i) => i.valid);

  int get _cartCheckedCount => _namedIngredients.where((i) => i.inCart).length;

  void _addIngredient() {
    setState(() => _ingredients.add(Ingredient()));
  }

  void _removeIngredient(int index) {
    if (_ingredients.length > 1) {
      setState(() {
        _ingredients.removeAt(index);
      });
    }
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
    _tabController.dispose();
    _mealNameController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Grocery Meal Cost Calculator',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calculate_outlined), text: 'Calculator'),
            Tab(
              icon: Icon(Icons.shopping_cart_outlined),
              text: 'Shopping List',
            ),
            Tab(icon: Icon(Icons.history), text: 'Previous Meals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalculatorTab(context),
          _buildShoppingListTab(context),
          MealHistoryView(
            meals: _savedMeals,
            loading: _historyLoading,
            hasError: _historyError,
            onRetry: _loadHistory,
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorTab(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _historyLoading || _historyError || _saving
                ? null
                : _saveMeal,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Saving...' : 'Save meal'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _ResponsiveFields(
              breakpoint: 600,
              children: [
                TextField(
                  controller: _mealNameController,
                  decoration: const InputDecoration(
                    labelText: 'Meal name',
                    hintText: 'e.g. Chicken Stir Fry',
                    prefixIcon: Icon(Icons.restaurant_menu),
                  ),
                ),
                TextField(
                  controller: _servingsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    errorText: _servings == null
                        ? 'Enter a whole number from 1 to 999999.'
                        : null,
                    errorMaxLines: 3,
                    labelText: 'Servings',
                    prefixIcon: Icon(Icons.people_outline),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Ingredients', style: theme.textTheme.titleMedium),
                const Text(
                  'Only named ingredients are included in totals, shopping and saved meals.',
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < _ingredients.length; i++) ...[
                  _IngredientRow(
                    key: ObjectKey(_ingredients[i]),
                    ingredient: _ingredients[i],
                    onChanged: () => setState(() {}),
                    onRemove: _ingredients.length > 1
                        ? () => _removeIngredient(i)
                        : null,
                  ),
                  if (i != _ingredients.length - 1) const Divider(height: 28),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
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
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 24,
                  runSpacing: 16,
                  children: [
                    _SummaryItem(
                      label: 'Total meal cost',
                      value: _validMeal
                          ? formatMoney(_totalCents)
                          : 'Check inputs',
                    ),
                    _SummaryItem(
                      label: 'Cost / serving',
                      value: _validMeal && _servings != null
                          ? formatMoney(servingCents(_totalCents, _servings!))
                          : 'Check inputs',
                    ),
                    _SummaryItem(
                      label: 'Ingredients',
                      value: '$_ingredientCount',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _resetAll,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShoppingListTab(BuildContext context) {
    final theme = Theme.of(context);
    final items = _namedIngredients;

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 56,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                'Add named ingredients in the Calculator tab to build your shopping list.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Card(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 24,
              runSpacing: 16,
              children: [
                _SummaryItem(
                  label: 'In cart',
                  value: '$_cartCheckedCount / ${items.length}',
                ),
                _SummaryItem(
                  label: 'Remaining cost',
                  value: _validRemaining
                      ? formatMoney(_remainingCents)
                      : 'Check inputs',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _ShoppingListTile(
                  ingredient: items[i],
                  onChanged: () => setState(() {}),
                ),
                if (i != items.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Wrap keeps fields keyed and mounted when the window crosses a breakpoint.
class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.children, this.breakpoint = 850});
  final List<Widget> children;
  final double breakpoint;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide =
          constraints.maxWidth >= breakpoint &&
          MediaQuery.textScalerOf(context).scale(1) <= 1.3;
      final width = wide
          ? (constraints.maxWidth - 12 * (children.length - 1)) /
                children.length
          : constraints.maxWidth;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (int i = 0; i < children.length; i++)
            SizedBox(key: ValueKey(i), width: width, child: children[i]),
        ],
      );
    },
  );
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    super.key,
    required this.ingredient,
    required this.onChanged,
    required this.onRemove,
  });
  final Ingredient ingredient;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _ResponsiveFields(
        children: [
          TextFormField(
            initialValue: ingredient.name,
            decoration: InputDecoration(
              labelText: 'Ingredient',
              isDense: true,
              helperText: ingredient.started && !ingredient.named
                  ? 'Unnamed: excluded from totals'
                  : null,
              helperMaxLines: 2,
            ),
            onChanged: (v) {
              ingredient.name = v;
              onChanged();
            },
          ),
          TextFormField(
            initialValue: ingredient.quantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Qty',
              isDense: true,
              errorText: ingredient.started ? ingredient.quantityError : null,
              errorMaxLines: 3,
            ),
            onChanged: (v) {
              ingredient.quantity = v;
              onChanged();
            },
          ),
          DropdownButtonFormField<String>(
            initialValue: ingredient.unit,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Unit', isDense: true),
            items: _unitOptions
                .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                .toList(),
            onChanged: (v) {
              ingredient.unit = v ?? 'unit';
              onChanged();
            },
          ),
          TextFormField(
            initialValue: ingredient.price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Price/unit',
              isDense: true,
              errorText: ingredient.started ? ingredient.priceError : null,
              errorMaxLines: 3,
            ),
            onChanged: (v) {
              ingredient.price = v;
              onChanged();
            },
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: Text(
              !ingredient.named
                  ? 'Not included'
                  : ingredient.valid
                  ? formatMoney(ingredient.cents)
                  : 'Check inputs',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Remove ingredient',
            onPressed: onRemove,
          ),
        ],
      ),
    ],
  );
}

class _ShoppingListTile extends StatelessWidget {
  const _ShoppingListTile({required this.ingredient, required this.onChanged});

  final Ingredient ingredient;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qtyLabel = [
      ingredient.quantity,
      ingredient.unit,
    ].where((s) => s.trim().isNotEmpty).join(' ');

    return CheckboxListTile(
      value: ingredient.inCart,
      onChanged: (v) {
        ingredient.inCart = v ?? false;
        onChanged();
      },
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        ingredient.name,
        style: theme.textTheme.bodyLarge?.copyWith(
          decoration: ingredient.inCart ? TextDecoration.lineThrough : null,
          color: ingredient.inCart ? theme.colorScheme.outline : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (qtyLabel.isNotEmpty) Text(qtyLabel),
          Text(
            ingredient.valid ? formatMoney(ingredient.cents) : 'Check inputs',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
