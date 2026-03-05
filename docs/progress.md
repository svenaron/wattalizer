# Implementation Progress

Tracks completion status per item in the implementation order (spec-supplement §S9).

## Phase 1: Foundation

| # | Item | Status | Notes |
|---|---|---|---|
| 1 | Data models (`lib/domain/models/`, `lib/core/`) | ✅ Done | `fromRow`/`toCompanion` added in Phase 2 (Step 8). |
| 2 | MapCurveCalculator | ✅ Done | Static `computeBatch` + instance `updateLive`/`reset`. 12 tests. |
| 3 | SummaryCalculator | ✅ Done | `computeEffortSummary` + `computeRideSummary`. 13 tests. |
| 4 | AutoLapDetector | ✅ Done | 4-state machine (IG3). `manualLap`/`endRide`. 19 tests. |
| 5 | RollingBaseline | ✅ Done | Circular buffer with freeze/unfreeze/clear. 10 tests. |
| 6 | EffortManager | ✅ Done | `createEffort` + `redetectEfforts`. 10 tests. |
| 7 | HistoricalRangeCalculator | ✅ Done | Single-pass O(n×90) best/worst envelopes with provenance. 6 tests. |

**Phase 1 total: 147 tests passing** (77 models/core + 70 services)

**Phase 2 total (Steps 8-12): 244 tests passing**

**Phase 3 total: 274 tests passing**

## Phase 2: Data Layer

| # | Item | Status |
|---|---|---|
| 8 | Database schema + Drift codegen | ✅ Done | 8 tables, `@DataClassName` row aliases, `database.g.dart` generated. `fromRow`/`toCompanion` on all 6 domain models. `RideRepository` interface complete. |
| 9 | LocalRideRepository | ✅ Done | 43 tests. Tag+filter via customSelect/GROUP BY, cascade delete, upserts. |
| 10 | BLE profile parsers (power, HR, CSC) | ✅ Done | `BleService` abstract interface + data types in `lib/domain/interfaces/ble_service.dart`. `PowerParser`, `HrParser`, `CscParser` in `lib/data/ble/`. 13 tests. |
| 11 | BleServiceImpl | ✅ Done | `flutter_reactive_ble` wrapper with exponential-backoff reconnect, per-device state maps, characteristic-level subscriptions. No unit tests (real hardware). |
| 12 | TcxSerializer + TcxParser | ✅ Done | `TcxSerializer.serialize()` builds Active/Resting laps. `TcxParser.parse()` flattens trackpoints, detects namespace prefix dynamically. `TcxParseResult` type. 41 tests (serializer + parser + round-trip). |

## Phase 3: Orchestration

| # | Item | Status |
|---|---|---|
| 13 | RideSessionManager | ✅ Done | Full IG17 + IG17.1 live-curve cache. Injectable wakelock. `transaction()` for atomic `end()`. 17 tests. |
| 14 | ExportService | ✅ Done | `exportTcx`, `importTcx` (dedup ±2s/±5%), `importZip` (per-file results). 13 tests. |

**Phase 3 total: 274 tests passing**

**Phase 4 total (Items 15-20): 278 tests passing — Phase 4 COMPLETE**

## Phase 4: Presentation

| # | Item | Status |
|---|---|---|
| 15 | Riverpod providers | ✅ Done | All providers implemented. `rideRepositoryProvider` uses override pattern (async DB open in `main()`). `NotifierProvider` used throughout (no legacy `StateProvider`). `dart analyze` clean. |
| 16 | Ride Screen (Idle / Focus / Chart modes) | ✅ Done | `RideScreen` + `_IdleView` / `_ActiveView` / `_RideControls` (1500ms long-press stop ring). `main.dart` wired. Focus mode (`ride_screen_focus.dart`) and Chart mode (`ride_screen_chart.dart`) scaffolded as stubs. |
| 17 | Device Connection Sheet | ✅ Done | `deviceListProvider` (autoDispose), `DeviceSheet` bottom sheet with remembered + scan sections, rename/auto-connect/forget. Wired into `_SensorStatusBar` tap and Start button. |
| 18 | History + Ride Detail screens | ✅ Done | `AppShell` with `NavigationBar` (4 tabs). `HistoryScreen` with span/tag filters, swipe-to-delete, ride cards. `RideDetailScreen` with tag editing, summary stats, effort timeline, expandable effort cards with MAP curve charts. `allTagsProvider`, `rideDetailProvider`. Widgets: `TagInput`, `EffortTimeline`, `MapCurveChart`, `EffortCard`. Sparkline deferred to Phase 5. |
| 19 | PDC screen | ✅ Done | Best envelope as bold line via `historicalRangeProvider`, historical band, key duration stat cards (1s/5s/15s/30s/60s/90s), provenance tooltips. Shared span/tag filters extracted to `SpanSelector`/`TagFilter` widgets. |
| 20 | Settings + Auto-Lap Config screen | ✅ Done | Settings: auto-lap config, max power (auto/manual via SharedPreferences), import (TCX/ZIP file picker), devices, appearance (dark/light/system). AutoLapConfigScreen: preset selector + 8 parameter fields + save as default. New providers: `exportServiceProvider`, `themeModeProvider`, `maxPowerOverrideProvider`. |

## Phase 4b: Desktop Support

| # | Item | Status |
|---|---|---|
| 20 | Platform scaffolding (macOS/Windows/Linux/Android dirs, entitlements, min window size) | 🔶 Partial | macOS platform added (`flutter create --platforms=macos`). Windows/Linux not yet added. |
| 21 | Responsive layout (breakpoints, AdaptiveShell, LayoutBuilder in RideScreen) | ⬜ Pending |
| 22 | Keyboard shortcuts (intents, shortcut map, Focus widget wiring) | ⬜ Pending |
| 23 | Desktop interaction polish (mouse cursors, tooltips, hover states, adaptive device dialog) | ⬜ Pending |

## Other

| Item | Status |
|---|---|
| Debug seeder (`lib/data/debug/`) | ✅ Done | `DebugSeeder` + `SyntheticPower` for dev testing with realistic synthetic data. |

## Phase 5: Polish

| # | Item | Status |
|---|---|---|
| 24 | Orientation handling + desktop window resize transitions | ⬜ Pending |
| 25 | Animations and transitions | ⬜ Pending |
| 26 | Re-detection preview | ⬜ Pending |
| 27 | Bulk import UI | ⬜ Pending |
