# Previous meals

Enter at least one named ingredient, then select **Save meal** in the Calculator.
The **Previous Meals** tab lists saved snapshots newest first. Select a meal to
view its saved date, servings, ingredients, prices, total, and cost per serving.
Blank meal names become "Untitled meal". Each save creates a separate snapshot.
Editing or resetting the calculator does not change saved meals.

History is stored locally using `SharedPreferencesAsync` and versioned JSON.
On web, storage belongs to the browser and site origin; other platforms use their
platform preferences storage. There is no account or cloud sync. Clearing app or
browser storage removes history. Calculator drafts are not automatically saved.
History is read-only in this version.

Read failures show a Retry action and disable saving to avoid overwriting unread
history. Write failures leave the displayed history unchanged and allow retry.

## Verification

Use Flutter with Dart 3.13.1 or newer, within Dart 3.x.

```sh
flutter pub get
flutter test
flutter analyze
```

History tests cover serialization, immutable snapshots, reloading through new
repository and widget instances, ordering, empty states, corrupt data, read/write
failures, retries, and pending saves. Automated unit/widget tests use the storage
package's in-memory platform implementation; they do not certify native disk
persistence on every supported device.

For a device smoke test, save a named meal, fully close and reopen the app, open
Previous Meals, and verify its ingredients and costs. Resetting the calculator
should leave that saved meal available.

## Calculator behavior (step 2)

Only named ingredients contribute to totals, the shopping list and new snapshots.
Unnamed rows display an exclusion notice. Named rows require a positive quantity
and a nonnegative price (zero is allowed for free ingredients). Inputs accept up
to twelve whole digits and six decimal places, using a decimal point. Fractions,
currency symbols, separators, exponent notation, negative and non-finite values
show validation errors. Servings must be a whole number from 1 to 999999.
Invalid named rows display "Check inputs" instead of a misleading total and cannot
be saved. Invalid servings suppress per-serving cost and block saving.

Costs use exact decimal multiplication and integer cents. Each ingredient rounds
half up to cents before totals are summed; per-serving cost also rounds half up.
New snapshots store cents as strings to retain precision on web. Older snapshots
remain readable; their stored row costs are rounded to cents for consistent totals.

Ingredient fields retain their values when rows are deleted or the screen resizes.
Reset creates fresh empty inputs. Narrow screens and large text stack fields and
wrap summaries. Regression tests cover these behaviors, including 320px width,
double-size text, rounding boundaries, and history compatibility. Full feature
coverage remains the separate step 3 checkpoint.
