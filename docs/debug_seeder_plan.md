# Plan: Debug Database Seeder

## Goal

Pre-populate the SQLite database with realistic fake rides in `kDebugMode` so the
History, Ride Detail, and PDC screens can be exercised without a TCX import or live
BLE session.

-----

## Context

- Framework: Flutter / Dart
- Database: Drift (`LocalRideRepository` implements `RideRepository`)
- Arch layer: `lib/data/` (data layer) with a call-site in app startup
- Gate: only runs when `kDebugMode == true` AND the database is empty
- Spec references: §4 (models), §5 (schema), §7 (MAP curve computation)

-----

## Files to create

### `lib/data/debug/debug_seeder.dart`

The seeder class. Takes a `RideRepository` as its only dependency.
No other imports from outside `lib/data/` or `lib/domain/`.

### `lib/data/debug/synthetic_power.dart`

Pure helper functions for generating fake power readings.
Stateless, no Flutter dependencies — makes it independently testable.

-----

## Files to modify

### `lib/main.dart` (or app initialisation entry point)

Add the one-time seed trigger after the repository is initialised and before
`runApp`. See §Trigger below.

-----

## Implementation: `synthetic_power.dart`

Expose one public function:

```dart
List<double?> generateRidePower({
  required int durationSeconds,
  required List<({int startOffset, int durationSeconds})> efforts,
  required double baselineWatts,
  required double peakWatts,
  int seed = 0,
})
```

### Algorithm

1. Fill the entire list with `baselineWatts` + small Gaussian noise (σ ≈ 12W).
1. For each effort window:
- Ramp up over `min(3, effort.durationSeconds ~/ 4)` seconds using a
  raised-cosine curve from baseline to `peakWatts`.
- Hold near peak (Gaussian noise σ ≈ 30W) for the middle portion.
- Decay back to baseline over the final `min(5, effort.durationSeconds ~/ 3)`
  seconds using an exponential decay.
1. Sprinkle ~1% null values at random offsets to simulate sensor dropout
   (skip effort windows — dropouts only in recovery).
1. Use a seeded PRNG (`math.Random(seed)`) so output is deterministic per ride.

Do **not** use `dart:math` `Random()` without a seed — determinism makes
debugging and snapshot tests reliable.

-----

## Implementation: `debug_seeder.dart`

### Class signature

```dart
class DebugSeeder {
  const DebugSeeder(this._repository);
  final RideRepository _repository;

  Future<void> seed() async { ... }
}
```

### Seed data specification

Generate **14 rides** as described in the table below. Dates are expressed as
offsets from `DateTime.now()` so the week/month/year filters on the History
screen all show meaningful subsets.

|# |Days ago|Duration|Tags                       |Efforts|Baseline|Peak |Notes          |
|--|--------|--------|---------------------------|-------|--------|-----|---------------|
|1 |0       |62 min  |track, flying 200          |6      |80W     |1180W|Today’s session|
|2 |1       |45 min  |trainer, short sprint      |4      |70W     |1040W|               |
|3 |3       |78 min  |track, team sprint, outdoor|8      |85W     |1240W|Many efforts   |
|4 |5       |55 min  |trainer                    |5      |65W     |980W |               |
|5 |7       |68 min  |track, flying 200          |6      |80W     |1150W|               |
|6 |10      |40 min  |track                      |3      |75W     |1090W|Short session  |
|7 |14      |72 min  |trainer, team sprint       |7      |70W     |1200W|               |
|8 |18      |50 min  |outdoor                    |4      |60W     |920W |Lower power day|
|9 |22      |65 min  |track, flying 200          |5      |80W     |1160W|               |
|10|30      |80 min  |track, outdoor             |9      |85W     |1260W|Best session   |
|11|45      |58 min  |trainer                    |5      |70W     |1010W|               |
|12|60      |70 min  |track, team sprint         |6      |80W     |1190W|               |
|13|90      |48 min  |trainer, short sprint      |4      |65W     |950W |               |
|14|120     |75 min  |track, outdoor             |7      |82W     |1220W|               |

### Effort placement

For a ride with N efforts spread across D minutes of total duration:

1. Divide the ride into N equal-width slots.
1. Place each effort at a random offset within its slot
   (`slotStart + Random.nextInt(slotWidth * 0.3)`).
1. Effort duration: `Random.nextInt(15) + 8` seconds (8–22s range).
1. Ensure at least 30 seconds of recovery between consecutive efforts.
1. No effort within the first 2 minutes or last 3 minutes of the ride.

### Per-ride generation steps

For each ride in the table above:

1. Compute `startTime = DateTime.now().subtract(Duration(days: daysAgo))`
   with a realistic morning start time (randomise between 06:00–09:30 local).
1. Place efforts using the algorithm above.
1. Call `generateRidePower(...)` from `synthetic_power.dart`.
1. Build `List<SensorReading>` — one per second:
- `power`: from generated array
- `heartRate`: baseline 85 BPM during recovery, ramp to 165–185 BPM over
  first 8s of effort, decay back over 20s after effort ends. Add ±5 BPM noise.
- `cadence`: 90–95 RPM during efforts, 60–70 RPM during recovery. Nullable
  during first 2s of each effort (sensor spin-up).
- All other fields: `null` (not needed for UI).
1. Build `List<Effort>` — one per effort window:
- `type`: `EffortType.auto`
- Compute `EffortSummary` using `SummaryCalculator.computeEffortSummary`.
1. Compute `MapCurve` for each effort using
   `MapCurveCalculator.computeBatch(readings)` where `readings` is the slice
   of the ride’s sensor readings bounded by the effort’s start/end offsets.
1. Compute `RideSummary` using `SummaryCalculator.computeRideSummary`.
1. Persist via `RideRepository`:
- Call `saveRide(ride)` to insert the ride row and all associated efforts,
  map curves, readings, and tags in a single transaction.
- Use the existing repository interface — do not reach into the Drift
  database directly.

### Error handling

Wrap the entire `seed()` body in a `try/catch`. On failure, log the error with
`debugPrint` and rethrow so startup fails loudly in debug mode rather than
silently producing a broken state.

-----

## Trigger (changes to `main.dart`)

Add the following after repository initialisation, before `runApp`:

```dart
import 'package:flutter/foundation.dart' show kDebugMode;
import 'data/debug/debug_seeder.dart';

// inside main() or initializeApp():
if (kDebugMode) {
  final rideCount = await rideRepository.getRideCount();
  if (rideCount == 0) {
    debugPrint('[DebugSeeder] Empty database — seeding...');
    await DebugSeeder(rideRepository).seed();
    debugPrint('[DebugSeeder] Done.');
  }
}
```

If `RideRepository` does not yet expose `getRideCount()`, add it:

- Interface: `Future<int> getRideCount();`
- Implementation (`LocalRideRepository`): `SELECT COUNT(*) FROM rides`

-----

## What NOT to do

- Do not use `flutter_test` fixtures or factory constructors — the seeder runs
  in the real app, not tests.
- Do not hardcode absolute `DateTime` values — always relative to `DateTime.now()`
  so the History screen filters stay meaningful over time.
- Do not bypass `RideRepository` — write through the existing interface so
  the seeder exercises the same code paths as real data.
- Do not ship this in release builds — the `kDebugMode` gate is mandatory.
  Do not add a `--dart-define` flag to expose it in release; if manual testing
  on a device is needed, use a debug build.

-----

## Acceptance criteria

- [ ] Running the app in debug mode with an empty database populates 14 rides.
- [ ] Re-running (hot restart, not full reinstall) does NOT re-seed.
- [ ] History screen shows rides distributed across week / month / year / all
  filter spans.
- [ ] Tag filter chips include at least: `track`, `trainer`, `outdoor`,
  `flying 200`, `short sprint`, `team sprint`.
- [ ] Each ride card shows a sparkline with visible effort peaks.
- [ ] Opening a Ride Detail shows the effort timeline bar with correct segments.
- [ ] Expanding an effort card renders its MAP curve against the historical envelope.
- [ ] PDC screen shows a non-trivial best envelope (not a flat line).
- [ ] No seeder code is reachable in a release build (`flutter build` with
  `--release` must compile cleanly with the seeder files present).
