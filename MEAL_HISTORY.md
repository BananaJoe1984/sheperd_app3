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

Step 1 adds history only. Numeric validation, row reset/deletion state, unnamed-row
consistency, responsive calculator layout, and exact currency rounding are tracked
for the next checkpoint.
