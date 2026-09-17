# Grocery Meal Cost Calculator

A Flutter app for estimating the cost of a meal, checking off its grocery list,
and looking back at meals saved on your device. The project package name is
`sheperd_app3`.

## What the app does

- **Calculator:** Enter a meal name, serving count, and ingredients with quantity,
  unit, and price per unit. Add or remove rows and see ingredient costs, total
  meal cost, cost per serving, and the number of named ingredients update live.
- **Shopping List:** View the same named ingredients as a checklist. Check items
  off to track how many are in your cart and how much remains to buy. Checked
  items stay included in the total meal cost.
- **Previous Meals:** Select **Save meal** to keep a local snapshot. Browse saved
  meals newest first and open their ingredients, prices, servings, costs, and
  saved date. Later edits or resets do not change those snapshots.
- **Responsive interface:** Material 3 styling with layouts that adapt to narrow
  screens and larger text, plus validation for quantities, prices, and servings.

## How to use it

1. In **Calculator**, enter a meal name and the number of servings (default: 4).
2. Name each ingredient and enter its quantity, unit, and price per unit.
3. Review the total and cost per serving. Use **Shopping List** while shopping.
4. Select **Save meal**, then open **Previous Meals** to review the snapshot.
5. Use **Reset** to start a fresh calculation without deleting saved history.

For example, 2 lb of chicken at $4.00 per lb costs $8.00. With four servings,
that ingredient contributes $2.00 per serving.

### Calculation rules

- Ingredient cost is quantity multiplied by price per unit. Each row rounds half
  up to cents before the meal total is summed; cost per serving also rounds half
  up to cents. Amounts display with a dollar sign.
- Units are labels: `unit`, `g`, `kg`, `ml`, `l`, `oz`, `lb`, `cup`, `tbsp`, and
  `tsp`. There is no automatic unit conversion or package-price calculation;
  enter the price for the unit you selected.
- Changing servings changes the cost per serving, not ingredient quantities.
- Only named ingredients appear in totals, the shopping list, and new saves.
- Quantities must be positive; prices may be zero. Decimal inputs support up to
  12 whole digits and 6 decimal places. Servings must be a whole number from 1
  to 999999. Invalid named ingredients or servings prevent saving.

## Local meal history

Meals are saved explicitly, not automatically. Each save creates a separate,
read-only snapshot; a blank meal name becomes **Untitled meal**. History uses
local platform preferences, or browser local storage on web. No account, server,
or cloud sync is required. Clearing app/browser storage removes saved history.
Unsaved calculator drafts do not survive a fresh session.

See [MEAL_HISTORY.md](MEAL_HISTORY.md) for storage behavior and error handling.

## Run locally

The tested SDK and CI use **Flutter 3.47.1**, which includes Dart 3.13.1.
Install Flutter and the platform tools for your target, then run:

```sh
flutter pub get
flutter run
```

The repository includes runners for Android, iOS, macOS, Windows, and web.
Platform builds and real-device persistence require their own smoke tests.

## Tests

```sh
flutter analyze
flutter test --coverage --concurrency=1
```

The suite covers calculator editing, validation and rounding, shopping-list
behavior, local history, storage errors, responsive layouts, and async lifecycle
handling. See [TESTING.md](TESTING.md) for the feature matrix, verification
results, and device checks. Coverage output is written to `coverage/lcov.info`.

## GitHub Actions

[Flutter CI](.github/workflows/main.yml) runs on pushes and pull requests and can
also be started manually from GitHub's **Actions** tab. It installs the pinned
Flutter SDK, checks dependencies against the lockfile, runs static analysis and
tests, and uploads an available coverage report as the **flutter-coverage**
artifact for 14 days. It does not build release packages or deploy the app.
