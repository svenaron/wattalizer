# Documentation Guide

Five documents, each with a specific purpose. You don't need to read all of them upfront — use the lookup table below.

## Documents

| Document | What it covers | When to read it |
|---|---|---|
| `spec-v1.1.md` | Full technical spec: features, architecture, data models, DB schema, BLE protocol details, UI/screen descriptions, testing strategy | **Read §1-2 first** for orientation. Reference specific sections as you implement each feature. |
| `spec-supplement.md` | Interface contracts (BleService, RideRepository, AutoLapDetector, etc.), active ride sequence flow, null handling rules, provider lifecycles, error types, implementation order | **Read §S9 (implementation order) before starting.** Reference contracts as you implement each interface. |
| `impl-guide.md` | IG1–IG11: file tree, RollingBaseline code, AutoLapDetector pseudocode, MapCurveCalculator with worked examples, HistoricalRangeCalculator example, 1Hz merge example, TCX examples, Drift table patterns, error handling patterns, test conventions, vertical slice | **Primary reference during implementation.** Contains complete/near-complete code for all domain services. |
| `impl-guide-models.md` | IG12–IG16: all domain model classes with Drift mapping, SummaryCalculator implementation, provider wiring patterns, BLE parser implementations with byte-level test fixtures, Readings table and batch insert | **Read when implementing models (Phase 1) and data layer (Phase 2).** |
| `impl-guide-orchestration.md` | IG17–IG19: RideSessionManager complete implementation, BleServiceImpl with reconnection, platform config (Info.plist, AndroidManifest), Ride Screen focus mode with power color scaling | **Read when implementing orchestration (Phase 3) and presentation (Phase 4).** |

## Lookup: "I'm implementing X, where do I look?"

| Task | Primary doc | Section |
|---|---|---|
| Data models (SensorReading, Ride, Effort, etc.) | impl-guide-models.md | IG12 |
| MapCurveCalculator | impl-guide.md | IG4 |
| AutoLapDetector | impl-guide.md | IG3 |
| RollingBaseline | impl-guide.md | IG2 |
| SummaryCalculator | impl-guide-models.md | IG13 |
| HistoricalRangeCalculator | impl-guide.md | IG5 |
| EffortManager | spec-supplement.md | S1.5 |
| Drift tables | impl-guide.md IG8 + impl-guide-models.md IG16 | All tables |
| LocalRideRepository | spec-supplement.md | S1.2 |
| BLE parsers (power, HR, CSC) | impl-guide-models.md | IG15 |
| BleServiceImpl | impl-guide-orchestration.md | IG18 |
| RideSessionManager | impl-guide-orchestration.md | IG17 |
| TCX export/import | impl-guide.md IG7 + spec-v1.1.md §8 | Combined |
| ExportService interface | spec-supplement.md | S1.6 |
| Riverpod providers | impl-guide-models.md IG14 + spec-supplement.md S4 | Combined |
| Ride Screen UI | impl-guide-orchestration.md | IG19 |
| Other screens | spec-v1.1.md | §9.4 |
| Auto-lap config presets | spec-v1.1.md §6.5 + impl-guide-models.md IG12.7 | Combined |
| Null handling in MAP | spec-supplement.md S3 + impl-guide.md IG4.2 | Combined |
| Testing patterns | impl-guide.md | IG10 |
| Error types | spec-supplement.md | S8 |
| 1Hz merge | impl-guide.md | IG6 |
| Active ride sequence | spec-supplement.md | S2 |
| Provider lifecycles | spec-supplement.md | S4 |
