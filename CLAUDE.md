# Sprint Power Analyzer

A cross-platform mobile app (Flutter/Dart) for track cyclists to analyze sprint power output. Connects to BLE power meters, auto-detects sprint efforts, computes MAP (Maximum Average Power) curves, and tracks personal records.

## Quick Start

```bash
flutter pub get
dart run build_runner build          # Drift codegen
flutter test                         # all tests, should pass before any changes
```

## Documentation

All specs and implementation guides are in `docs/`. Read `docs/CLAUDE.md` first — it explains what each document covers and when to reference which one.

**Do not start coding without reading `docs/CLAUDE.md`.**

See `docs/progress.md` for current implementation status.

## Architecture

Three-layer architecture with strict dependency rules. See `lib/CLAUDE.md` for the full picture.

```
presentation → domain → data interfaces
                         ↑
                    data implements
```

## Implementation Order

Follow the phased order in `docs/spec-supplement.md` §S9. Each phase should be fully tested before moving to the next:

1. **Foundation** — domain models, calculators, state machine (pure Dart, no Flutter)
2. **Data Layer** — database, BLE parsers, TCX serialization
3. **Orchestration** — RideSessionManager, ExportService
4. **Presentation** — providers, screens, widgets
5. **Polish** — animations, re-detection preview, bulk import

## Key Commands

```bash
dart format .                             # format all code
dart fix --apply                          # run static code analysis
flutter test                              # all tests
flutter test test/domain/                 # domain only (fastest, run often)
dart run build_runner build               # regenerate Drift code after table changes
flutter run                               # run on connected device/emulator
```

## Conventions

- **Models**: immutable plain Dart classes, no codegen (no freezed). Manual `copyWith` where needed.
- **State management**: Riverpod. See `lib/presentation/CLAUDE.md` for provider lifecycle rules.
- **Tests**: one test file per source file, mirrored path. Run `flutter test` after every completed item.
- **Errors**: sealed `AppError` hierarchy. Repository throws → provider catches → UI shows. Never swallow errors.
- **Null vs zero**: null = sensor dropout, zero = valid reading (e.g., coasting). This distinction matters everywhere.

## Code Quality

- After writing or modifying Dart files, run `dart format .` then `dart fix --apply` then `dart analyze` and fix any warnings
- After modifying models or providers, run `dart run build_runner build --delete-conflicting-outputs`
- Run `flutter test` after significant changes to verify nothing is broken