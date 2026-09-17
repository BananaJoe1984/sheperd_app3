# Testing

Run from the project root with the Flutter SDK used by this project:

```sh
flutter pub get
flutter test --coverage --concurrency=1
flutter analyze
```

The sequential setting avoids a Flutter compiler-cache collision observed on
Windows. Tests require no Trello, GitHub, grocery API, account, or live user data.
Coverage is written to `coverage/lcov.info` (ignored by Git).

Step 3 verification: **36 tests passed**, `flutter analyze` reported no issues,
and measured application line coverage was **436/436 (100%)** across the five
files in `lib/`. This does not imply exhaustive branch or device coverage.

## Feature coverage

| Feature | Automated checks | Test file |
| --- | --- | --- |
| Startup and theme | Real app entry point, default fields, three tabs, Material 3 | `features_test.dart`, `widget_test.dart` |
| Meal name and servings | Trimmed/fallback names, servings change only per-serving cost, invalid servings block save | `features_test.dart`, `meal_history_test.dart` |
| Ingredient editing | Add, edit, delete, preserve remaining fields/units, prevent deletion of final row | `features_test.dart`, `calculator_fixes_test.dart` |
| Units | Select all ten labels, display quantity/unit in shopping, persist selected unit | `features_test.dart` |
| Reset | Clear rendered fields and units, restore defaults, clear cart, retain saved history | `calculator_fixes_test.dart`, `features_test.dart`, `meal_history_test.dart` |
| Cost calculation | Exact multiplication, half-cent rounding, totals/per-serving/cart/history reconciliation, very large amounts | `calculator_fixes_test.dart` |
| Input validation | Empty/negative/non-finite/malformed numbers, precision limits, free ingredients, errors and save blocking | `calculator_fixes_test.dart`, `features_test.dart` |
| Unnamed rows | Consistent exclusion from totals, ingredient count, shopping and new snapshots | `calculator_fixes_test.dart` |
| Shopping list | Empty state, check/uncheck, strike-through, count, remaining cost, edit propagation, invalid cost handling | `features_test.dart`, `calculator_fixes_test.dart` |
| Saved meals | Save, newest-first ordering, separate snapshots, detail/back navigation, reload after widget/repository recreation | `features_test.dart`, `meal_history_test.dart` |
| Local storage | JSON round-trip, old snapshot compatibility, immutable snapshots, corrupt data preservation, read/write failures and retry | `meal_history_test.dart`, `calculator_fixes_test.dart` |
| Async lifecycle | Loading state, disabled save while loading/writing, completion after screen disposal | `meal_history_test.dart` |
| Responsive layout | 320px/390px/768px widths, doubled text, resize preserves values/units, large amounts | `calculator_fixes_test.dart` |

Files above are under `test/`. Shared interaction helpers live in
`test/support/calculator_test_helpers.dart`. Tests assert user-visible behavior,
saved values and calculated amounts, not only whether widgets build.

## Limits and device smoke test

Unit/widget tests replace the preferences platform with an in-memory store. They
exercise the production repository and serialization, but do not verify actual
disk persistence or every native platform build. Line coverage is a measure of
executed source, not proof that every possible input or platform works.

For each device/browser you intend to release on:

1. Run the app, enter a named meal with ingredients and save it.
2. Fully close and reopen the app (reload the same origin for web).
3. Verify the saved meal's ingredients, units, servings and costs.
4. Edit/reset the calculator and confirm the saved snapshot stays unchanged.
5. Check/uncheck shopping items and try the layout with larger system text.

No changes to production application behavior are intended in the step 3 test
checkpoint.
