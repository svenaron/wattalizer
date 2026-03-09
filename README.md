<img src="assets/icon/wattalizer_icon.svg" alt="Wattalizer" width="96">

# Wattalizer

A sprint power analyzer for track cyclists. Record rides live with a BLE power meter, or import existing rides from Garmin, Wahoo, or Strava — and get instant Maximum Average Power curves for every effort, personal records, and historical trends over time.

Available on macOS, Windows, and Linux.

## Two ways to use it

**Live recording** — connect a BLE power meter, start a session, and see MAP curves computed in real time as you ride. Auto-lap detection picks up each sprint automatically.

**Import from your head unit** — load TCX or FIT files exported from Garmin Connect, Wahoo, Strava, or any compatible device. All the same analysis applies: effort detection, MAP curves, personal records, and historical comparisons.

## Features

- **Real-time MAP curves** — Maximum Average Power for durations 1–90 seconds, computed live per effort
- **TCX/FIT import** — analyze rides from Garmin, Wahoo, Strava, or any compatible device
- **Auto-lap detection** — delta-based sprint detection adapts to any riding intensity
- **Personal records** — all-time Power Duration Curve with drill-down to source efforts
- **Session analysis** — overlay efforts to see fatigue across intervals
- **Historical envelopes** — best/worst performance bands behind live data
- **Multi-athlete profiles** — switch between athletes; each has isolated rides, settings, and records
- **BLE sensor support** — power meters, heart rate straps, cadence sensors
- **TCX export** — share rides back to Strava, Garmin Connect, and other platforms
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
