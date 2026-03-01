# Presentation Layer

Flutter UI + Riverpod providers. Implement in Phase 4 after orchestration is working.

## providers/

See IG14 for concrete wiring patterns and S4 for the complete lifecycle table.

### Lifecycle rules:
- **keepAlive**: `bleConnectionProvider`, `sensorStreamProvider`, `rideSessionProvider`, `activeEffortProvider`, `sessionEffortsProvider`, `spanSelectionProvider`, `tagFilterProvider`, `autoLapConfigProvider`, `maxPowerProvider`
- **autoDispose**: `historicalRangeProvider`, `rideListProvider`, `deviceListProvider`

### Key patterns:
- `rideSessionProvider` is a `NotifierProvider` exposing sealed `RideState` (Idle/Active/Error). See IG14.1.
- `activeEffortProvider` is a derived `Provider` that extracts effort state from ride session. See IG14.2.
- `historicalRangeProvider` is a `FutureProvider.autoDispose` depending on `spanSelectionProvider` and `tagFilterProvider`. See IG14.3.
- On ride end, `rideSessionProvider` invalidates `historicalRangeProvider` and `maxPowerProvider`.

### Provider → provider dependencies:
```
rideSessionProvider → sensorStreamProvider, rideRepositoryProvider, autoLapConfigProvider
activeEffortProvider → rideSessionProvider
sessionEffortsProvider → rideSessionProvider
historicalRangeProvider → spanSelectionProvider, tagFilterProvider, rideRepositoryProvider
rideListProvider → spanSelectionProvider, tagFilterProvider, rideRepositoryProvider
maxPowerProvider → rideRepositoryProvider
```

## screens/

See spec §9.4 for what each screen shows. See IG19 for the Ride Screen focus mode as a complete reference implementation.

### Ride Screen (`ride_screen.dart`)
The home screen. Uses `ref.watch(rideSessionProvider)` and pattern-matches on `RideState`:
- `RideStateIdle` → last ride summary card + Start button
- `RideStateActive` → Focus or Chart mode (swipe to toggle, or segmented control)
- `RideStateError` → error message

Split into sub-files for readability:
- `ride_screen_focus.dart` — big power number, color-coded background (IG19)
- `ride_screen_chart.dart` — live MAP curve with historical band (IG19.1)

### Other screens
- `history_screen.dart` — scrollable ride list, filtered by span + tags. Spec §9.4.3.
- `ride_detail_screen.dart` — ride stats, effort timeline, expandable effort cards. Spec §9.4.4.
- `pdc_screen.dart` — power duration curve chart with provenance drill-down. Spec §9.4.5.
- `settings_screen.dart` — auto-lap config, max power, import, devices, theme. Spec §9.4.6.
- `autolap_config_screen.dart` — preset selector + parameter fields. Spec §9.4.7.

### Interaction details:
- Focus ↔ Chart: **horizontal swipe only** (80px minimum) or segmented control pills. No tap-to-toggle.
- Stop ride: **long-press 1.5s** with circular progress indicator.
- Landscape: always chart mode, auto-detected via `OrientationBuilder`.
- Screen stays awake during active ride (wakelock).

## widgets/

Reusable components. `map_curve_chart.dart` is the most complex — uses `fl_chart` to render MAP curves with historical bands. See IG19.1 for the data-binding pattern.

### Design notes:
- Dark theme default. Respect system theme setting.
- Focus mode power number: ~96pt, readable at arm's length.
- Charts: bold gradient line for live effort (red→yellow→blue), faded lines for previous efforts, shaded band for historical best/worst.
- Effort timeline: horizontal colored bar segments, intensity-coded by avg power.
- Tag input: top 2–5 most frequent tags as tappable chips, text field with autocomplete for the rest.
