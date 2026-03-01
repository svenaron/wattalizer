# Domain Layer

Pure Dart. No Flutter imports. No platform dependencies. This is the core of the app and should be implemented and tested first (Phase 1 in S9).

## models/

All immutable plain Dart classes with `const` constructors. Complete implementations in IG12. Each model has:
- `factory fromRow()` for Drift row → domain model
- `toCompanion()` for domain model → Drift insert companion
- `copyWith()` only where mutation patterns exist (Ride, DeviceInfo)

**Critical**: `SensorReading` has ~20 nullable fields. All sensor fields null = dropout. Zero is valid data.

## interfaces/

Abstract contracts that the data layer implements. **Do not put implementation details here.**
- `ble_service.dart` — see S1.1
- `ride_repository.dart` — see S1.2

## services/

Each service has detailed implementation guidance. Reference the lookup table in `docs/CLAUDE.md`.

### Implementation order (within Phase 1):
1. `rolling_baseline.dart` — IG2 has complete code. Simple circular buffer. Implement and test first.
2. `map_curve_calculator.dart` — IG4 has complete code + worked example. Prefix sums with null handling. Test with IG4.2 expected values.
3. `summary_calculator.dart` — IG13 has complete code. Active-effort-only averaging for RideSummary is the subtle part.
4. `autolap_detector.dart` — IG3 has complete pseudocode. Four-state machine. Test every edge case from spec §6.4.
5. `effort_manager.dart` — S1.5 has the contract. Depends on MapCurveCalculator and SummaryCalculator.
6. `historical_range_calculator.dart` — IG5 has worked example. Single-pass best/worst with provenance.

### ride_session_manager.dart
The hardest piece. Implement in Phase 3 after the data layer is done. IG17 has the complete implementation. This class:
- Owns the 1Hz timer and BLE stream subscription
- Accumulates raw notifications into 1-second bins (IG6 for merge rules)
- Feeds merged readings to AutoLapDetector
- Creates/disposes live MapCurveCalculator per effort
- Builds Effort objects when efforts end
- Persists everything in a single transaction on ride end

### export_service.dart
Phase 3. S1.6 has the contract. Orchestrates TCX serializer/parser + file I/O.

## events/

`autolap_events.dart` — `EffortStartedEvent` and `EffortEndedEvent`. See S1.3 for the sealed class hierarchy.
