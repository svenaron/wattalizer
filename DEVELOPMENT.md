# Development

## Prerequisites

- Flutter SDK (stable channel)
- Dart SDK (comes with Flutter)

## Building

```bash
flutter pub get
dart run build_runner build          # Drift codegen (required after table changes)
flutter run                          # default device
flutter run -d macos                 # macOS
flutter run -d windows               # Windows
flutter run -d linux                 # Linux
```

## Testing

```bash
flutter test                         # all tests
flutter test test/domain/            # domain only (fastest, run often)
```

## Code quality

```bash
dart format .
dart fix --apply
dart analyze
```

## Architecture

Flutter/Dart, three-layer architecture: `presentation → domain → data interfaces ← data`.

- **Domain** — pure Dart, no Flutter, no Drift imports
- **Data** — implements domain interfaces (BLE, SQLite, TCX)
- **Presentation** — Riverpod providers + Flutter widgets

See [`docs/spec.md`](docs/spec.md) for the full technical specification and [`docs/progress.md`](docs/progress.md) for implementation history.

## License

MIT
