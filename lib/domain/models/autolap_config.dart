import 'package:drift/drift.dart';
import 'package:wattalizer/data/database/database.dart';

class AutoLapConfig {
  const AutoLapConfig({
    required this.id,
    required this.name,
    required this.startDeltaWatts,
    required this.endDeltaWatts,
    this.startConfirmSeconds = 2,
    this.startDropoutTolerance = 1,
    this.endConfirmSeconds = 5,
    this.minEffortSeconds = 3,
    this.preEffortBaselineWindow = 15,
    this.inEffortTrailingWindow = 10,
    this.isDefault = false,
  });

  // --- Presets (from spec §6.5) ---

  factory AutoLapConfig.shortSprint({String? id}) => AutoLapConfig(
        id: id ?? 'preset_short_sprint',
        name: 'Short Sprint',
        startDeltaWatts: 200,
        startConfirmSeconds: 1,
        endDeltaWatts: 150,
        endConfirmSeconds: 4,
        minEffortSeconds: 2,
        preEffortBaselineWindow: 10,
        inEffortTrailingWindow: 5,
      );

  factory AutoLapConfig.flying200({String? id}) => AutoLapConfig(
        id: id ?? 'preset_flying_200',
        name: 'Flying 200m',
        startDeltaWatts: 150,
        endDeltaWatts: 120,
        minEffortSeconds: 5,
        inEffortTrailingWindow: 8,
      );

  factory AutoLapConfig.teamSprint({String? id}) => AutoLapConfig(
        id: id ?? 'preset_team_sprint',
        name: 'Team Sprint',
        startDeltaWatts: 120,
        startConfirmSeconds: 3,
        endDeltaWatts: 100,
        endConfirmSeconds: 6,
        minEffortSeconds: 10,
        preEffortBaselineWindow: 20,
        inEffortTrailingWindow: 15,
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
      isDefault: row.isDefault,
    );
  }

  AutolapConfigsCompanion toCompanion() {
    return AutolapConfigsCompanion.insert(
      id: id,
      name: name,
      startDeltaWatts: startDeltaWatts,
      startConfirmSeconds: Value(startConfirmSeconds),
      startDropoutTolerance: Value(startDropoutTolerance),
      endDeltaWatts: endDeltaWatts,
      endConfirmSeconds: Value(endConfirmSeconds),
      minEffortSeconds: Value(minEffortSeconds),
      preEffortBaselineWindow: Value(preEffortBaselineWindow),
      inEffortTrailingWindow: Value(inEffortTrailingWindow),
      isDefault: Value(isDefault),
    );
  }

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
      isDefault: isDefault ?? this.isDefault,
    );
  }

  final String id;
  final String name;
  final double startDeltaWatts;
  final int startConfirmSeconds;
  final int startDropoutTolerance;
  final double endDeltaWatts;
  final int endConfirmSeconds;
  final int minEffortSeconds;
  final int preEffortBaselineWindow;
  final int inEffortTrailingWindow;
  final bool isDefault;
}
