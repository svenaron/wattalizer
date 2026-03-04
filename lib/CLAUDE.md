# Source Code Architecture

## Layer Rules

```
presentation/  → can import domain/ and core/
domain/        → can import core/ only (NEVER data/)
data/          → can import domain/interfaces/ and domain/models/ and core/
core/          → imports nothing from this project
```

**domain/ must never import from data/.** Domain defines abstract interfaces (BleService, RideRepository) in `domain/interfaces/`. Data layer implements them. Presentation wires them together via Riverpod providers.

## Layer Responsibilities

### core/
Shared utilities only. Constants (durations 1..90, default config values), the `AppError` sealed class hierarchy, and Dart extension methods. No business logic.

### domain/
All business logic lives here. Pure Dart — no Flutter, no platform dependencies.

- **models/**: immutable data classes. No codegen. See `docs/impl-guide-models.md` IG12 for complete implementations including Drift `toCompanion()`/`fromRow()` mapping.
- **interfaces/**: abstract classes defining contracts for BLE and persistence. See `docs/spec-supplement.md` S1.1–S1.2.
- **services/**: the core algorithms and orchestration. Each has a corresponding implementation guide section:
  - `rolling_baseline.dart` → IG2 (complete code)
  - `autolap_detector.dart` → IG3 (complete pseudocode)
  - `map_curve_calculator.dart` → IG4 (complete code + worked example)
  - `historical_range_calculator.dart` → IG5 (worked example)
  - `summary_calculator.dart` → IG13 (complete code)
  - `effort_manager.dart` → S1.5 (contract)
  - `ride_session_manager.dart` → IG17 (complete implementation)
  - `export_service.dart` → S1.6 (contract)
- **events/**: AutoLap event types (EffortStartedEvent, EffortEndedEvent)

### data/
Platform-dependent implementations.

- **ble/**: `flutter_reactive_ble` wrapper and BLE profile parsers. See `docs/impl-guide-orchestration.md` IG18 and `docs/impl-guide-models.md` IG15.
- **database/**: Drift/SQLite. See `docs/impl-guide.md` IG8 and `docs/impl-guide-models.md` IG16.
- **tcx/**: XML serialization. See `docs/impl-guide.md` IG7 and `docs/spec.md` §8.

### presentation/
Flutter UI and Riverpod state management. See `lib/presentation/CLAUDE.md`.

## Critical Design Decisions

1. **Null vs zero**: null power = sensor dropout (skip in MAP calc). Zero power = coasting (include in MAP calc). This applies everywhere: models, parsers, calculators, TCX export/import, database.

2. **Readings not on Ride**: `Ride` objects never hold readings in memory. Readings are always lazy-loaded via `RideRepository.getReadings()`. During an active ride, readings live in `RideSessionManager._readings` buffer and are batch-written to DB on ride end.

3. **MapCurve per effort, not per ride**: MAP curves are computed and cached per effort. Ride-level PDC is derived on demand by taking `max(effort.curve[d])` across all efforts — not stored separately.

4. **Monotonicity enforcement**: every MAP curve, PDC, and historical envelope must be non-increasing. Sweep right-to-left after computation. Set `wasEnforced` flag.
