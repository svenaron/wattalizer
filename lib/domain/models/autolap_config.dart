import 'package:drift/drift.dart';
import 'package:wattalizer/data/database/database.dart';

class AutoLapConfig {
  const AutoLapConfig({
    required this.name,
    required this.startDeltaWatts,
    required this.endDeltaWatts,
    this.id,
    this.startConfirmSeconds = 2,
    this.startDropoutTolerance = 1,
    this.endConfirmSeconds = 5,
    this.minEffortSeconds = 3,
    this.preEffortBaselineWindow = 15,
    this.inEffortTrailingWindow = 10,
    this.minPeakWatts,
    this.isDefault = false,
  });

  // --- Presets (from spec §6.5) ---

  factory AutoLapConfig.standingStart() => const AutoLapConfig(
        name: 'Standing Start',
        startDeltaWatts: 350,
        endDeltaWatts: 250,
        startConfirmSeconds: 1,
        endConfirmSeconds: 4,
        minEffortSeconds: 2,
        preEffortBaselineWindow: 10,
        inEffortTrailingWindow: 5,
        minPeakWatts: 700,
      );

  factory AutoLapConfig.flyingStart() => const AutoLapConfig(
        name: 'Flying Start',
        startDeltaWatts: 150,
        endDeltaWatts: 150,
        minEffortSeconds: 5,
        inEffortTrailingWindow: 8,
        minPeakWatts: 700,
      );

  factory AutoLapConfig.broad() => const AutoLapConfig(
        name: 'Broad',
        startDeltaWatts: 120,
        endDeltaWatts: 100,
        startConfirmSeconds: 1,
        endConfirmSeconds: 3,
        minEffortSeconds: 2,
        inEffortTrailingWindow: 8,
        minPeakWatts: 400,
      );

  factory AutoLapConfig.fromRow(AutolapConfigRow row) {
    return AutoLapConfig(
      id: row.id,
      name: row.name,
      startDeltaWatts: row.startDeltaWatts,
      startConfirmSeconds: row.startConfirmSeconds,
      startDropoutTolerance: row.startDropoutTolerance,
      endDeltaWatts: row.endDeltaWatts,
      endConfirmSeconds: row.endConfirmSeconds,
      minEffortSeconds: row.minEffortSeconds,
      preEffortBaselineWindow: row.preEffortBaselineWindow,
      inEffortTrailingWindow: row.inEffortTrailingWindow,
      minPeakWatts: row.minPeakWatts,
      isDefault: row.isDefault,
    );
  }

  AutolapConfigsCompanion toCompanion() {
    return AutolapConfigsCompanion.insert(
      id: id != null ? Value(id!) : const Value.absent(),
      name: name,
      startDeltaWatts: startDeltaWatts,
      startConfirmSeconds: Value(startConfirmSeconds),
      startDropoutTolerance: Value(startDropoutTolerance),
      endDeltaWatts: endDeltaWatts,
      endConfirmSeconds: Value(endConfirmSeconds),
      minEffortSeconds: Value(minEffortSeconds),
      preEffortBaselineWindow: Value(preEffortBaselineWindow),
      inEffortTrailingWindow: Value(inEffortTrailingWindow),
      minPeakWatts: Value(minPeakWatts),
      isDefault: Value(isDefault),
    );
  }

  static const _sentinel = Object();

  AutoLapConfig copyWith({
    String? name,
    double? startDeltaWatts,
    int? startConfirmSeconds,
    int? startDropoutTolerance,
    double? endDeltaWatts,
    int? endConfirmSeconds,
    int? minEffortSeconds,
    int? preEffortBaselineWindow,
    int? inEffortTrailingWindow,
    Object? minPeakWatts = _sentinel,
    bool? isDefault,
  }) {
    return AutoLapConfig(
      id: id,
      name: name ?? this.name,
      startDeltaWatts: startDeltaWatts ?? this.startDeltaWatts,
      startConfirmSeconds: startConfirmSeconds ?? this.startConfirmSeconds,
      startDropoutTolerance:
          startDropoutTolerance ?? this.startDropoutTolerance,
      endDeltaWatts: endDeltaWatts ?? this.endDeltaWatts,
      endConfirmSeconds: endConfirmSeconds ?? this.endConfirmSeconds,
      minEffortSeconds: minEffortSeconds ?? this.minEffortSeconds,
      preEffortBaselineWindow:
          preEffortBaselineWindow ?? this.preEffortBaselineWindow,
      inEffortTrailingWindow:
          inEffortTrailingWindow ?? this.inEffortTrailingWindow,
      minPeakWatts: identical(minPeakWatts, _sentinel)
          ? this.minPeakWatts
          : minPeakWatts as double?,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  final int? id;
  final String name;
  final double startDeltaWatts;
  final int startConfirmSeconds;
  final int startDropoutTolerance;
  final double endDeltaWatts;
  final int endConfirmSeconds;
  final int minEffortSeconds;
  final int preEffortBaselineWindow;
  final int inEffortTrailingWindow;
  final double? minPeakWatts;
  final bool isDefault;
}
