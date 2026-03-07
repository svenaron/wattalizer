# Wattalizer

[![Build & Test](https://github.com/svenaron/wattalizer/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/svenaron/wattalizer/actions/workflows/ci.yml)

A cross-platform mobile app for track cyclists and sprint athletes to analyze power output during sprint interval training.

## Features

- **Real-time MAP curves** — Maximum Average Power for durations 1–90 seconds, computed live per effort
- **Auto-lap detection** — delta-based sprint detection adapts to any riding intensity
- **Personal records** — all-time Power Duration Curve with drill-down to source efforts
- **Session analysis** — overlay efforts to see fatigue across intervals
- **Historical envelopes** — best/worst performance bands behind live data
- **BLE sensor support** — power meters, heart rate straps, cadence sensors
- **TCX import/export** — interoperability with Strava, Garmin Connect, etc.
- **Focus mode** — large power display with intensity-coded background for mid-sprint glanceability

## Getting Started

```bash
flutter pub get
dart run build_runner build
flutter run
```

## Architecture

Flutter/Dart with Riverpod state management, Drift/SQLite persistence, and flutter_reactive_ble for sensor communication. Three-layer architecture: presentation → domain → data.

See `docs/` for the full technical specification.

## License

This project is licensed under the terms of the MIT license.
