# Implementation Progress

Tracks completion status per item in the implementation order (spec-supplement §S9).

## Phase 1: Foundation

| # | Item | Status | Notes |
|---|---|---|---|
| 1 | Data models (`lib/domain/models/`, `lib/core/`) | ✅ Done | Pure Dart, no Drift. `fromRow`/`toCompanion` deferred to Phase 2. |
| 2 | MapCurveCalculator | ✅ Done | Static `computeBatch` + instance `updateLive`/`reset`. 12 tests. |
| 3 | SummaryCalculator | ✅ Done | `computeEffortSummary` + `computeRideSummary`. 13 tests. |
| 4 | AutoLapDetector | ✅ Done | 4-state machine (IG3). `manualLap`/`endRide`. 19 tests. |
| 5 | RollingBaseline | ✅ Done | Circular buffer with freeze/unfreeze/clear. 10 tests. |
| 6 | EffortManager | ✅ Done | `createEffort` + `redetectEfforts`. 10 tests. |
| 7 | HistoricalRangeCalculator | ✅ Done | Single-pass O(n×90) best/worst envelopes with provenance. 6 tests. |

**Phase 1 total: 147 tests passing** (77 models/core + 70 services)

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
