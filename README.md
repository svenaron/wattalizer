# Wattalizer

A sprint power analyzer for track cyclists. Connect a BLE power meter, ride, and get instant Maximum Average Power curves for every effort — plus personal records and historical trends over time.

Available on macOS, Windows, and Linux.

## Features

- **Real-time MAP curves** — Maximum Average Power for durations 1–90 seconds, computed live per effort
- **Auto-lap detection** — delta-based sprint detection adapts to any riding intensity
- **Personal records** — all-time Power Duration Curve with drill-down to source efforts
- **Session analysis** — overlay efforts to see fatigue across intervals
- **Historical envelopes** — best/worst performance bands behind live data
- **Multi-athlete profiles** — switch between athletes; each has isolated rides, settings, and records
- **BLE sensor support** — power meters, heart rate straps, cadence sensors
- **TCX import/export** — interoperability with Strava, Garmin Connect, etc.
- **Focus mode** — large power display with intensity-coded background for mid-sprint glanceability

## Sensors

Connects to standard Bluetooth Low Energy sensors using open profiles:

| Profile | Examples |
|---|---|
| Cycling Power (0x1818) | Favero Assioma, Garmin Vector, SRM, Quarq |
| Heart Rate (0x180D) | Garmin, Polar, Wahoo Tickr |
| Cycling Speed & Cadence (0x1816) | Garmin, Wahoo |

## License

This project is licensed under the terms of the MIT license.

---

For build instructions and architecture docs, see [DEVELOPMENT.md](DEVELOPMENT.md).
