# Implementation Progress

Tracks completion status per item in the implementation order (spec-supplement §S9).

## Phase 1: Foundation

| # | Item | Status | Notes |
|---|---|---|---|
| 1 | Data models (`lib/domain/models/`, `lib/core/`) | ✅ Done | Pure Dart, no Drift. `fromRow`/`toCompanion` deferred to Phase 2. |
| 2 | MapCurveCalculator | ⬜ Pending | |
| 3 | SummaryCalculator | ⬜ Pending | |
| 4 | AutoLapDetector | ⬜ Pending | |
| 5 | RollingBaseline | ⬜ Pending | |
| 6 | EffortManager | ⬜ Pending | |
| 7 | HistoricalRangeCalculator | ⬜ Pending | |

## Phase 2: Data Layer

| # | Item | Status |
|---|---|---|
| 8 | Database schema + Drift codegen | ⬜ Pending |
| 9 | LocalRideRepository | ⬜ Pending |
| 10 | BLE profile parsers (power, HR, CSC) | ⬜ Pending |
| 11 | BleServiceImpl | ⬜ Pending |
| 12 | TcxSerializer + TcxParser | ⬜ Pending |

## Phase 3: Orchestration

| # | Item | Status |
|---|---|---|
| 13 | RideSessionManager | ⬜ Pending |
| 14 | ExportService | ⬜ Pending |

## Phase 4: Presentation

| # | Item | Status |
|---|---|---|
| 15 | Riverpod providers | ⬜ Pending |
| 16 | Ride Screen (Idle / Focus / Chart modes) | ⬜ Pending |
| 17 | Device Connection Sheet | ⬜ Pending |
| 18 | History + Ride Detail screens | ⬜ Pending |
| 19 | PDC screen | ⬜ Pending |
| 20 | Settings + Auto-Lap Config screen | ⬜ Pending |

## Phase 5: Polish

| # | Item | Status |
|---|---|---|
| 21 | Orientation handling | ⬜ Pending |
| 22 | Animations and transitions | ⬜ Pending |
| 23 | Re-detection preview | ⬜ Pending |
| 24 | Bulk import UI | ⬜ Pending |
