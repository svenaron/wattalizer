# Wattalizer

A cross-platform app (Flutter/Dart, mobile & desktop) for track cyclists to analyze sprint power output. Targets iOS, Android, macOS, Windows, and Linux. Connects to BLE power meters, auto-detects sprint efforts, computes MAP (Maximum Average Power) curves, and tracks personal records.

## Quick Start

```bash
flutter pub get
dart run build_runner build          # Drift codegen
flutter test                         # all tests, should pass before any changes
```

## Documentation

- `docs/spec.md` — full technical spec: features, architecture, data models, BLE protocol, UI descriptions, testing strategy
- `docs/progress.md` — implementation history and completion status

## Architecture

Three-layer architecture with strict dependency rules. See `lib/CLAUDE.md` for the full picture.

```
presentation → domain → data interfaces
                         ↑
                    data implements
```

## Key Commands

```bash
dart format .                             # format all code
dart fix --apply                          # auto-fix issues from static analysis
dart analyze                              # run static analysis
flutter test                              # all tests
flutter test test/domain/                 # domain only (fastest, run often)
dart run build_runner build               # regenerate Drift code after table changes
flutter run                               # run on connected device/emulator
flutter run -d macos                      # run on macOS
flutter run -d windows                    # run on Windows
flutter run -d linux                      # run on Linux
```

## Conventions

- **Models**: immutable plain Dart classes, no codegen (no freezed). Manual `copyWith` where needed.
- **State management**: Riverpod. See `lib/presentation/CLAUDE.md` for provider lifecycle rules.
- **Tests**: one test file per source file, mirrored path. Run `flutter test` after every completed item.
- **Errors**: sealed `AppError` hierarchy. Repository throws → provider catches → UI shows. Never swallow errors.
- **Null vs zero**: null = sensor dropout, zero = valid reading (e.g., coasting). This distinction matters everywhere.
- **Line length**: max 80 columns in all Dart files. Lint will reject longer lines.

## Code Quality

- After writing or modifying Dart files, run `dart format .` then `dart fix --apply` then `dart analyze` and fix any warnings
- After modifying models or providers, run `dart run build_runner build --delete-conflicting-outputs`
- Run `flutter test` after significant changes to verify nothing is broken