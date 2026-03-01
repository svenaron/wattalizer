# Data Layer

Implements domain interfaces. Three sub-packages.

## ble/

**`ble_service_impl.dart`** — wraps `flutter_reactive_ble`. See IG18 for complete implementation. Key points:
- Connection manages the full state machine internally (scan → connect → discover services → subscribe to characteristics)
- Reconnection: exponential backoff 1s→2s→4s→...→30s cap, give up after 2 minutes
- Subscribes to all supported characteristics on a device and merges into a single `RawSensorData` stream
- Reset CSC parser on reconnect to avoid bogus deltas

**Parsers** (`power_parser.dart`, `hr_parser.dart`, `csc_parser.dart`) — see IG15 for complete code + byte-level test fixtures.
- Power and HR parsers are **stateless** (pure functions)
- CSC parser is **stateful** (needs previous reading for delta-based cadence)
- All use little-endian byte order
- Power parser must handle variable-length structure driven by 16-bit flags field — parse fields in order, advancing offset correctly even for fields we skip

## database/

**`tables.dart`** — all Drift table definitions. See IG8 (Rides, Efforts, MapCurves) and IG16 (Readings, AppSettings, Devices, AutolapConfigs, RideTags). After changing tables, run:
```bash
dart run build_runner build
```

**`database.dart`** — `AppDatabase` class. See IG16.2 for custom index creation in `onCreate`. Indexes:
- `readings(ride_id, offset_seconds)` — composite, most important for performance
- `rides(start_time DESC)`
- `efforts(ride_id)`
- `map_curves(effort_id)`
- `ride_tags(tag)`

**`local_ride_repository.dart`** — implements `RideRepository` from `domain/interfaces/`. See S1.2 for the full interface contract and IG16.1 for batch insert pattern. Key:
- Ride save uses a single DB transaction (ride + readings + efforts + map_curves)
- Ride delete cascades to efforts, readings, map_curves, ride_tags
- `getAllEffortCurves()` joins efforts → rides for date/tag filtering
- Tags normalized to lowercase and trimmed on write

## tcx/

**`tcx_serializer.dart`** — Ride + readings → TCX XML string. See IG7.1 for complete output example. Key:
- Efforts → Active laps, gaps → Resting laps
- Null fields → element omitted entirely (not `<Watts>0</Watts>`)
- All timestamps in UTC with `Z` suffix
- All raw sensor fields exported (see spec §8.1)

**`tcx_parser.dart`** — TCX XML → Ride + readings. See IG7.2 for parsing rules. Key:
- **All source laps are discarded** — flatten trackpoints into continuous stream
- Detect namespace prefix dynamically (ns3, tpx, ax2, etc.)
- Missing `<Watts>` element = null (dropout). `<Watts>0</Watts>` = coasting (valid zero)
- Timestamps: see S7 for timezone handling rules
