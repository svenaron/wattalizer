# Testing Guide

## Conventions

- One test file per source file, mirrored path: `lib/domain/services/foo.dart` → `test/domain/foo_test.dart`
- Use `group()` per public method/behavior
- Helper functions at bottom of file (e.g., `_reading(int offset, {double? power})`)
- See IG10 for a complete test file example (MapCurveCalculator)

## Run Commands

```bash
flutter test                          # everything
flutter test test/domain/             # domain only — fastest, run after every change
flutter test test/data/               # data layer — needs Flutter test environment
flutter test test/presentation/       # widget + provider tests
```

**Run `flutter test` after completing each numbered item in S9.**

## Priority

Domain tests are highest priority. They're pure Dart (fast, no Flutter), and they validate all business logic.

## What to Test per Service

### `map_curve_calculator_test.dart`
- Known sequence → expected values (use IG4.2 worked example)
- All-null readings → all zeros
- Monotonicity property: any input produces non-increasing output
- `hadNulls` flag when best window contains null
- `wasEnforced` flag when monotonicity bumps a value
- **Live vs batch equivalence**: same input must produce identical output

### `autolap_detector_test.dart`
- Clean sprint (clear start/stop)
- Noisy sprint (mid-effort dips within dropout tolerance)
- Too-short spike (discarded by minEffortSeconds)
- Back-to-back efforts with/without adequate recovery
- Cold start (baseline = 0)
- Gradual ramp (no false trigger)
- Sensor dropout mid-effort (nulls ignored)
- Ride end in each of the 4 states
- Manual lap in each of the 4 states

### `rolling_baseline_test.dart`
- Buffer filling and windowed average
- Freeze stops updates, unfreeze resumes
- Clear resets everything
- Empty buffer returns 0.0

### `historical_range_calculator_test.dart`
- Best/worst with provenance from multiple efforts (use IG5 example)
- Monotonicity on both envelopes
- Provenance inherited on enforcement bump
- Single effort: best = worst

### `summary_calculator_test.dart`
- All-null readings → no NaN, zeros
- Mixed null/value averaging
- kJ computation
- **RideSummary active-effort-only**: avgPower excludes recovery readings
- Zero efforts → activeDuration = 0, avgPower = 0

### `effort_manager_test.dart`
- Creates effort with correct slice, summary, and MAP curve
- restSincePrevious computed correctly
- Re-detection produces different efforts with different config

## Data Layer Tests

### Parser tests (`power_parser_test.dart`, etc.)
- Use byte array fixtures from IG15.2–15.4
- Cover all flag combinations for power parser
- CSC rollover handling
- CSC reset clears state

### `local_ride_repository_test.dart`
- Use Drift in-memory database
- Ride CRUD round-trip
- Batch insert 3600+ readings in transaction
- Cascade delete (ride → efforts → readings → map_curves → tags)
- Tag filtering (AND logic)
- Date range filtering

### TCX tests
- `tcx_serializer_test.dart`: ride → XML, verify structure
- `tcx_parser_test.dart`: XML → ride, verify fields
- `tcx_round_trip_test.dart`: export → import → compare (null → omit → null preserved)

## Presentation Tests

### `providers_test.dart`
- Mock BLE and repository
- Sensor reading → session → effort flow
- Span change → historical range recomputed

### `ride_screen_test.dart`
- Each RideState renders correct widgets
- Swipe gesture toggles mode
- LAP/STOP buttons present in active state
