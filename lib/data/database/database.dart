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
  int get schemaVersion => 4;

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
          await _seedBuiltInConfigs(m.database);
        },
        onUpgrade: (m, from, to) async {
          if (from < 4) {
            // Drop and recreate all tables (no user data yet in prod).
            for (final entity in allSchemaEntities.toList().reversed) {
              await m.drop(entity);
            }
            await m.createAll();
            await _seedBuiltInConfigs(m.database);
            return;
          }
        },
      );

  static Future<void> _seedBuiltInConfigs(DatabaseConnectionUser db) async {
    const cols = 'INSERT INTO autolap_configs '
        '(name, start_delta_watts, '
        'start_confirm_seconds, start_dropout_tolerance, '
        'end_delta_watts, end_confirm_seconds, min_effort_seconds, '
        'pre_effort_baseline_window, in_effort_trailing_window, '
        'min_peak_watts, is_default) VALUES ';
    await db.customStatement(
      "$cols('Standing Start', 350.0, 1, 1, 250.0, 4, 2, 10, 5, 700.0, 1)",
    );
    await db.customStatement(
      "$cols('Flying Start', 150.0, 2, 1, 150.0, 5, 5, 15, 8, 700.0, 0)",
    );
    await db.customStatement(
      "$cols('Broad', 120.0, 1, 1, 100.0, 3, 2, 15, 8, 400.0, 0)",
    );
  }
}
