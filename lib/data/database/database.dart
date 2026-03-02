import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:wattalizer/data/database/tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Rides,
    RideTags,
    Efforts,
    MapCurves,
    Readings,
    AppSettings,
    Devices,
    AutolapConfigs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Opens the production SQLite database on-device.
  static Future<AppDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'wattalizer.db');
    final executor = NativeDatabase.createInBackground(File(dbPath));
    return AppDatabase(executor);
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Custom composite / covering indexes not expressible in table DSL
          await m.database.customStatement(
            'CREATE INDEX idx_readings_ride_offset '
            'ON readings (ride_id, offset_seconds)',
          );
          await m.database.customStatement(
            'CREATE INDEX idx_rides_start_time '
            'ON rides (start_time DESC)',
          );
          await m.database.customStatement(
            'CREATE INDEX idx_efforts_ride '
            'ON efforts (ride_id)',
          );
          await m.database.customStatement(
            'CREATE INDEX idx_map_curves_effort '
            'ON map_curves (effort_id)',
          );
          await m.database.customStatement(
            'CREATE INDEX idx_ride_tags_tag '
            'ON ride_tags (tag)',
          );
        },
        onUpgrade: (m, from, to) async {
          // Future migrations go here
        },
      );
}
