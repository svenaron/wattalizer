import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/data/database/database.dart';
import 'package:wattalizer/data/database/local_ride_repository.dart';
import 'package:wattalizer/domain/models/autolap_config.dart';
import 'package:wattalizer/domain/models/device_info.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/effort_summary.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/domain/models/ride_summary.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';

// --- Test Helpers ---

MapCurve _makeMapCurve(String entityId, {double baseValue = 10.0}) {
  return MapCurve(
    entityId: entityId,
    values: List.generate(90, (i) => baseValue + i),
    flags: List.generate(90, (_) => const MapCurveFlags()),
    computedAt: DateTime(2024),
  );
}

Effort _makeEffort(
  String id,
  String rideId, {
  int effortNumber = 1,
  int startOffset = 0,
  int endOffset = 10,
}) {
  return Effort(
    id: id,
    rideId: rideId,
    effortNumber: effortNumber,
    startOffset: startOffset,
    endOffset: endOffset,
    type: EffortType.auto,
    summary: const EffortSummary(
      durationSeconds: 10,
      avgPower: 500,
      peakPower: 800,
    ),
    mapCurve: _makeMapCurve(id),
  );
}

Ride _makeRide(
  String id, {
  List<String> tags = const [],
  String? notes,
  List<Effort> efforts = const [],
  DateTime? startTime,
}) {
  return Ride(
    id: id,
    startTime: startTime ?? DateTime(2024, 1, 1, 10),
    source: RideSource.recorded,
    tags: tags,
    notes: notes,
    efforts: efforts,
    summary: const RideSummary(
      durationSeconds: 3600,
      activeDurationSeconds: 600,
      avgPower: 250,
      maxPower: 1200,
      readingCount: 3600,
      effortCount: 3,
    ),
  );
}

SensorReading _makeReading(int offsetSeconds, {double? power}) {
  return SensorReading(
    timestamp: Duration(seconds: offsetSeconds),
    power: power,
    heartRate: 150,
  );
}

/// Saves a ride and its efforts+map_curves separately (mirrors
/// how RideSessionManager.end() persists data after Bug 2 fix).
/// saveEfforts already inserts map_curves, so no separate saveMapCurve needed.
Future<void> _saveRideWithEfforts(LocalRideRepository repo, Ride ride) async {
  await repo.saveRide(ride);
  if (ride.efforts.isNotEmpty) {
    await repo.saveEfforts(ride.id, ride.efforts);
  }
}

void main() {
  late AppDatabase db;
  late LocalRideRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = LocalRideRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  // --- saveRide / getRide ---

  group('saveRide / getRide', () {
    test('round-trip preserves id, startTime, source, summary', () async {
      final ride = _makeRide('r1');
      await repo.saveRide(ride);
      final loaded = await repo.getRide('r1');

      expect(loaded, isNotNull);
      expect(loaded!.id, 'r1');
      expect(loaded.startTime, ride.startTime);
      expect(loaded.source, RideSource.recorded);
      expect(loaded.summary.durationSeconds, 3600);
      expect(loaded.summary.avgPower, 250.0);
      expect(loaded.summary.readingCount, 3600);
    });

    test('round-trip preserves notes', () async {
      final ride = _makeRide('r1', notes: 'Morning session');
      await repo.saveRide(ride);
      final loaded = await repo.getRide('r1');

      expect(loaded!.notes, 'Morning session');
    });

    test('round-trip preserves tags (normalized to lowercase)', () async {
      final ride = _makeRide('r1', tags: ['Sprint', ' Track ', 'competition']);
      await repo.saveRide(ride);
      final loaded = await repo.getRide('r1');

      expect(loaded!.tags, containsAll(['sprint', 'track', 'competition']));
      expect(loaded.tags.length, 3);
    });

    test('duplicate tags are deduplicated', () async {
      final ride = _makeRide('r1', tags: ['sprint', 'Sprint', 'SPRINT']);
      await repo.saveRide(ride);
      final loaded = await repo.getRide('r1');

      expect(loaded!.tags, ['sprint']);
    });

    test('round-trip preserves efforts with map curves', () async {
      final effort = _makeEffort('e1', 'r1');
      final ride = _makeRide('r1', efforts: [effort]);
      await _saveRideWithEfforts(repo, ride);
      final loaded = await repo.getRide('r1');

      expect(loaded!.efforts.length, 1);
      final loadedEffort = loaded.efforts.first;
      expect(loadedEffort.id, 'e1');
      expect(loadedEffort.effortNumber, 1);
      expect(loadedEffort.summary.avgPower, 500.0);
      expect(loadedEffort.mapCurve.values.length, 90);
      expect(loadedEffort.mapCurve.values[0], 10.0); // baseValue + 0
      expect(loadedEffort.mapCurve.values[89], 99.0); // baseValue + 89
    });

    test('multiple efforts are ordered by effortNumber', () async {
      final e1 = _makeEffort('e1', 'r1');
      final e2 = _makeEffort('e2', 'r1', effortNumber: 2);
      final e3 = _makeEffort('e3', 'r1', effortNumber: 3);
      final ride = _makeRide('r1', efforts: [e3, e1, e2]); // out of order
      await _saveRideWithEfforts(repo, ride);
      final loaded = await repo.getRide('r1');

      expect(loaded!.efforts.map((e) => e.effortNumber).toList(), [1, 2, 3]);
    });

    test('returns null for unknown id', () async {
      final result = await repo.getRide('nonexistent');
      expect(result, isNull);
    });
  });

  // --- updateRide ---

  group('updateRide', () {
    test('updates notes and tags, preserves summary', () async {
      final ride = _makeRide('r1', notes: 'original', tags: ['track']);
      await repo.saveRide(ride);

      final updated = ride.copyWith(notes: 'updated', tags: ['sprint', 'comp']);
      await repo.updateRide(updated);

      final loaded = await repo.getRide('r1');
      expect(loaded!.notes, 'updated');
      expect(loaded.tags, containsAll(['sprint', 'comp']));
      expect(loaded.summary.durationSeconds, 3600); // unchanged
    });

    test('can clear notes by setting to null', () async {
      final ride = _makeRide('r1', notes: 'some note');
      await repo.saveRide(ride);

      // copyWith uses `??` so can't clear nullable fields — construct directly
      final cleared = Ride(
        id: 'r1',
        startTime: ride.startTime,
        source: ride.source,
        summary: ride.summary,
      );
      await repo.updateRide(cleared);
      final loaded = await repo.getRide('r1');
      expect(loaded!.notes, isNull);
    });

    test('can clear all tags', () async {
      final ride = _makeRide('r1', tags: ['sprint', 'track']);
      await repo.saveRide(ride);

      await repo.updateRide(ride.copyWith(tags: []));
      final loaded = await repo.getRide('r1');
      expect(loaded!.tags, isEmpty);
    });
  });

  // --- deleteRide ---

  group('deleteRide', () {
    test(
      'cascades: removes ride, efforts, readings, map_curves, tags',
      () async {
        final effort = _makeEffort('e1', 'r1');
        final ride = _makeRide('r1', tags: ['sprint'], efforts: [effort]);
        await _saveRideWithEfforts(repo, ride);
        await repo.insertReadings('r1', [_makeReading(1), _makeReading(2)]);

        await repo.deleteRide('r1');

        expect(await repo.getRide('r1'), isNull);
        expect(await repo.getEfforts('r1'), isEmpty);
        expect(await repo.getReadings('r1'), isEmpty);

        // Verify map_curves are gone
        final remaining = await (db.select(
          db.mapCurves,
        )..where((t) => t.effortId.equals('e1')))
            .get();
        expect(remaining, isEmpty);

        // Verify tags are gone
        final tags = await (db.select(
          db.rideTags,
        )..where((t) => t.rideId.equals('r1')))
            .get();
        expect(tags, isEmpty);
      },
    );
  });

  // --- insertReadings / getReadings ---

  group('insertReadings / getReadings', () {
    test('batch insert and retrieval ordered by offset', () async {
      await repo.saveRide(_makeRide('r1'));
      final readings = [
        _makeReading(3, power: 300),
        _makeReading(1, power: 100),
        _makeReading(2, power: 200),
      ];
      await repo.insertReadings('r1', readings);

      final loaded = await repo.getReadings('r1');
      expect(loaded.length, 3);
      expect(loaded[0].timestamp.inSeconds, 1);
      expect(loaded[1].timestamp.inSeconds, 2);
      expect(loaded[2].timestamp.inSeconds, 3);
    });

    test('null power (sensor dropout) is preserved', () async {
      await repo.saveRide(_makeRide('r1'));
      await repo.insertReadings('r1', [_makeReading(1)]);

      final loaded = await repo.getReadings('r1');
      expect(loaded.first.power, isNull);
    });

    test('start/end offset range is inclusive', () async {
      await repo.saveRide(_makeRide('r1'));
      final readings = List.generate(
        10,
        (i) => _makeReading(i, power: i * 10.0),
      );
      await repo.insertReadings('r1', readings);

      final range = await repo.getReadings('r1', startOffset: 2, endOffset: 5);
      expect(range.length, 4); // offsets 2, 3, 4, 5
      expect(range.first.timestamp.inSeconds, 2);
      expect(range.last.timestamp.inSeconds, 5);
    });

    test('batch insert 3600+ readings in a single transaction', () async {
      await repo.saveRide(_makeRide('r1'));
      final readings = List.generate(
        3601,
        (i) => _makeReading(i, power: 200.0 + i % 100),
      );
      await repo.insertReadings('r1', readings);

      final loaded = await repo.getReadings('r1');
      expect(loaded.length, 3601);
    });
  });

  // --- saveEfforts ---

  group('saveEfforts', () {
    test('replaces all existing efforts atomically', () async {
      final ride = _makeRide('r1', efforts: [_makeEffort('e1', 'r1')]);
      await _saveRideWithEfforts(repo, ride);

      final newEfforts = [
        _makeEffort('e2', 'r1'),
        _makeEffort('e3', 'r1', effortNumber: 2),
      ];
      await repo.saveEfforts('r1', newEfforts);

      final loaded = await repo.getEfforts('r1');
      expect(loaded.length, 2);
      expect(loaded.map((e) => e.id).toList(), containsAll(['e2', 'e3']));
      expect(loaded.any((e) => e.id == 'e1'), isFalse);

      // Old map_curves are gone
      final oldCurves = await (db.select(
        db.mapCurves,
      )..where((t) => t.effortId.equals('e1')))
          .get();
      expect(oldCurves, isEmpty);
    });
  });

  // --- getRides ---

  group('getRides', () {
    test('returns all rides ordered by startTime desc', () async {
      await repo.saveRide(_makeRide('r1', startTime: DateTime(2024)));
      await repo.saveRide(_makeRide('r2', startTime: DateTime(2024, 3)));
      await repo.saveRide(_makeRide('r3', startTime: DateTime(2024, 2)));

      final results = await repo.getRides();
      expect(results.map((r) => r.id).toList(), ['r2', 'r3', 'r1']);
    });

    test('date range filter: from only', () async {
      await repo.saveRide(_makeRide('r1', startTime: DateTime(2024)));
      await repo.saveRide(_makeRide('r2', startTime: DateTime(2024, 6)));

      final results = await repo.getRides(from: DateTime(2024, 3));
      expect(results.map((r) => r.id), ['r2']);
    });

    test('date range filter: to only', () async {
      await repo.saveRide(_makeRide('r1', startTime: DateTime(2024)));
      await repo.saveRide(_makeRide('r2', startTime: DateTime(2024, 6)));

      final results = await repo.getRides(to: DateTime(2024, 3));
      expect(results.map((r) => r.id), ['r1']);
    });

    test('date range filter: from and to', () async {
      await repo.saveRide(_makeRide('r1', startTime: DateTime(2024)));
      await repo.saveRide(_makeRide('r2', startTime: DateTime(2024, 4)));
      await repo.saveRide(_makeRide('r3', startTime: DateTime(2024, 8)));

      final results = await repo.getRides(
        from: DateTime(2024, 2),
        to: DateTime(2024, 6),
      );
      expect(results.map((r) => r.id), ['r2']);
    });

    test('tag AND filter: ride must have ALL specified tags', () async {
      await repo.saveRide(_makeRide('r1', tags: ['sprint', 'track']));
      await repo.saveRide(_makeRide('r2', tags: ['sprint']));
      await repo.saveRide(_makeRide('r3', tags: ['track']));

      final results = await repo.getRides(tags: {'sprint', 'track'});
      expect(results.map((r) => r.id), ['r1']);
    });

    test('tag filter: ride with only one of two tags is excluded', () async {
      await repo.saveRide(_makeRide('r1', tags: ['sprint']));

      final results = await repo.getRides(tags: {'sprint', 'track'});
      expect(results, isEmpty);
    });

    test('limit and offset pagination', () async {
      for (var i = 1; i <= 5; i++) {
        await repo.saveRide(_makeRide('r$i', startTime: DateTime(2024, i)));
      }

      final page1 = await repo.getRides(limit: 2);
      expect(page1.length, 2);
      expect(page1.first.id, 'r5'); // most recent first

      final page2 = await repo.getRides(limit: 2, offset: 2);
      expect(page2.length, 2);
      expect(page2.first.id, 'r3');
    });

    test('includes tags in summary rows', () async {
      await repo.saveRide(_makeRide('r1', tags: ['alpha', 'beta']));

      final results = await repo.getRides();
      expect(results.first.tags, containsAll(['alpha', 'beta']));
    });
  });

  // --- getAllTags ---

  group('getAllTags', () {
    test('returns distinct tags sorted alphabetically', () async {
      await repo.saveRide(_makeRide('r1', tags: ['sprint', 'track']));
      await repo.saveRide(_makeRide('r2', tags: ['track', 'competition']));

      final tags = await repo.getAllTags();
      expect(tags, ['competition', 'sprint', 'track']);
    });

    test('returns empty list when no rides', () async {
      expect(await repo.getAllTags(), isEmpty);
    });
  });

  // --- saveMapCurve / getMapCurve ---

  group('saveMapCurve / getMapCurve', () {
    test('90-value round-trip with flags preserved', () async {
      final curve = MapCurve(
        entityId: 'e1',
        values: List.generate(90, (i) => (i + 1) * 5.0),
        flags: List.generate(
          90,
          (i) => MapCurveFlags(hadNulls: i.isEven, wasEnforced: i % 3 == 0),
        ),
        computedAt: DateTime(2024),
      );

      // Need a ride + effort row for the effortId FK
      await _saveRideWithEfforts(
        repo,
        _makeRide('r1', efforts: [_makeEffort('e1', 'r1')]),
      );
      // Clear auto-saved curve and save custom one
      await (db.delete(
        db.mapCurves,
      )..where((t) => t.effortId.equals('e1')))
          .go();

      await repo.saveMapCurve('e1', curve);
      final loaded = await repo.getMapCurve('e1');

      expect(loaded, isNotNull);
      expect(loaded!.values[0], 5.0);
      expect(loaded.values[89], 450.0);
      expect(loaded.flags[0].hadNulls, isTrue);
      expect(loaded.flags[1].hadNulls, isFalse);
      expect(loaded.flags[0].wasEnforced, isTrue);
      expect(loaded.flags[1].wasEnforced, isFalse);
    });

    test('returns null for unknown entityId', () async {
      expect(await repo.getMapCurve('nonexistent'), isNull);
    });
  });

  // --- saveRidePdc / getRidePdc ---

  group('saveRidePdc / getRidePdc', () {
    test('round-trip via map_curves table', () async {
      await repo.saveRide(_makeRide('r1'));
      final pdc = _makeMapCurve('r1', baseValue: 300);

      await repo.saveRidePdc('r1', pdc);
      final loaded = await repo.getRidePdc('r1');

      expect(loaded, isNotNull);
      expect(loaded!.entityId, 'r1');
      expect(loaded.values[0], 300.0);
    });

    test('saveRidePdc replaces existing PDC', () async {
      await repo.saveRide(_makeRide('r1'));
      await repo.saveRidePdc('r1', _makeMapCurve('r1', baseValue: 100));
      await repo.saveRidePdc('r1', _makeMapCurve('r1', baseValue: 200));

      final loaded = await repo.getRidePdc('r1');
      expect(loaded!.values[0], 200.0);
    });

    test('returns null for ride with no PDC', () async {
      await repo.saveRide(_makeRide('r1'));
      expect(await repo.getRidePdc('r1'), isNull);
    });
  });

  // --- getAllEffortCurves ---

  group('getAllEffortCurves', () {
    test('returns all effort curves when no filters applied', () async {
      final ride1 = _makeRide(
        'r1',
        efforts: [
          _makeEffort('e1', 'r1'),
          _makeEffort('e2', 'r1', effortNumber: 2),
        ],
      );
      final ride2 = _makeRide('r2', efforts: [_makeEffort('e3', 'r2')]);
      await _saveRideWithEfforts(repo, ride1);
      await _saveRideWithEfforts(repo, ride2);

      final curves = await repo.getAllEffortCurves();
      expect(curves.length, 3);
      expect(curves.map((c) => c.effortId).toSet(), {'e1', 'e2', 'e3'});
    });

    test('provenance fields are correct', () async {
      final ride = _makeRide(
        'r1',
        startTime: DateTime(2024, 6, 15),
        efforts: [_makeEffort('e1', 'r1', effortNumber: 2)],
      );
      await _saveRideWithEfforts(repo, ride);

      final curves = await repo.getAllEffortCurves();
      expect(curves.length, 1);
      final c = curves.first;
      expect(c.effortId, 'e1');
      expect(c.rideId, 'r1');
      expect(c.rideDate, DateTime(2024, 6, 15));
      expect(c.effortNumber, 2);
    });

    test('date range filter excludes out-of-range rides', () async {
      final ride1 = _makeRide(
        'r1',
        startTime: DateTime(2024),
        efforts: [_makeEffort('e1', 'r1')],
      );
      final ride2 = _makeRide(
        'r2',
        startTime: DateTime(2024, 6),
        efforts: [_makeEffort('e2', 'r2')],
      );
      await _saveRideWithEfforts(repo, ride1);
      await _saveRideWithEfforts(repo, ride2);

      final curves = await repo.getAllEffortCurves(
        from: DateTime(2024, 3),
        to: DateTime(2024, 12),
      );
      expect(curves.length, 1);
      expect(curves.first.effortId, 'e2');
    });

    test('returns empty list when no efforts match', () async {
      await repo.saveRide(_makeRide('r1'));

      final curves = await repo.getAllEffortCurves();
      expect(curves, isEmpty);
    });
  });

  // --- saveDevice / getRememberedDevices / deleteDevice ---

  group('devices', () {
    final device = DeviceInfo(
      deviceId: 'd1',
      displayName: 'PowerMeter Pro',
      supportedServices: {SensorType.power},
      lastConnected: DateTime(2024),
    );

    test('saveDevice and getRememberedDevices round-trip', () async {
      await repo.saveDevice(device);
      final devices = await repo.getRememberedDevices();

      expect(devices.length, 1);
      expect(devices.first.deviceId, 'd1');
      expect(devices.first.displayName, 'PowerMeter Pro');
      expect(devices.first.autoConnect, isTrue);
    });

    test('saveDevice upserts on conflict', () async {
      await repo.saveDevice(device);
      final updated = DeviceInfo(
        deviceId: 'd1',
        displayName: 'Updated Name',
        supportedServices: {SensorType.power},
        lastConnected: DateTime(2024, 6),
        autoConnect: false,
      );
      await repo.saveDevice(updated);

      final devices = await repo.getRememberedDevices();
      expect(devices.length, 1);
      expect(devices.first.displayName, 'Updated Name');
      expect(devices.first.autoConnect, isFalse);
    });

    test('deleteDevice removes device', () async {
      await repo.saveDevice(device);
      await repo.deleteDevice('d1');

      expect(await repo.getRememberedDevices(), isEmpty);
    });

    test('getAutoConnectDevices returns only autoConnect=true', () async {
      await repo.saveDevice(device); // autoConnect: true
      final noConnect = DeviceInfo(
        deviceId: 'd2',
        displayName: 'Manual Device',
        supportedServices: {SensorType.heartRate},
        lastConnected: DateTime(2024),
        autoConnect: false,
      );
      await repo.saveDevice(noConnect);

      final autoDevices = await repo.getAutoConnectDevices();
      expect(autoDevices.length, 1);
      expect(autoDevices.first.deviceId, 'd1');
    });
  });

  // --- AutoLap config ---

  group('autoLap configs', () {
    setUp(() async {
      // Clear seeded configs so tests start with a blank slate.
      await db.delete(db.autolapConfigs).go();
    });

    test('getDefaultConfig returns standingStart values when table is empty',
        () async {
      final config = await repo.getDefaultConfig();
      // No rows in table → fallback to AutoLapConfig.standingStart()
      expect(config.name, 'Standing Start');
      expect(config.startDeltaWatts, 350);
    });

    test('saveAutoLapConfig insert assigns auto-increment id', () async {
      const config = AutoLapConfig(
        name: 'My Config',
        startDeltaWatts: 180,
        endDeltaWatts: 130,
      );
      final id = await repo.saveAutoLapConfig(config);

      expect(id, isPositive);
      final configs = await repo.getAutoLapConfigs();
      expect(configs.length, 1);
      expect(configs.first.name, 'My Config');
      expect(configs.first.startDeltaWatts, 180.0);
      expect(configs.first.id, id);
    });

    test('saveAutoLapConfig update preserves id', () async {
      const config = AutoLapConfig(
        name: 'Config 1',
        startDeltaWatts: 150,
        endDeltaWatts: 100,
      );
      final id = await repo.saveAutoLapConfig(config);
      final updated = AutoLapConfig(
        id: id,
        name: 'Config 1 Updated',
        startDeltaWatts: 160,
        endDeltaWatts: 110,
      );
      final returnedId = await repo.saveAutoLapConfig(updated);

      expect(returnedId, id);
      final configs = await repo.getAutoLapConfigs();
      expect(configs.length, 1);
      expect(configs.first.name, 'Config 1 Updated');
    });

    test(
      'saveAutoLapConfig clears previous default when setting new one',
      () async {
        const config1 = AutoLapConfig(
          name: 'Config 1',
          startDeltaWatts: 150,
          endDeltaWatts: 100,
          isDefault: true,
        );
        const config2 = AutoLapConfig(
          name: 'Config 2',
          startDeltaWatts: 200,
          endDeltaWatts: 150,
          isDefault: true,
        );
        final id1 = await repo.saveAutoLapConfig(config1);
        await repo.saveAutoLapConfig(config2);

        final defaultConfig = await repo.getDefaultConfig();
        expect(defaultConfig.name, 'Config 2');

        // config1 should no longer be default
        final all = await repo.getAutoLapConfigs();
        expect(all.firstWhere((c) => c.id == id1).isDefault, isFalse);
      },
    );
  });

  group('deleteAutoLapConfig', () {
    setUp(() async {
      await db.delete(db.autolapConfigs).go();
    });

    test('deletes one of two configs and returns true', () async {
      final id1 = await repo.saveAutoLapConfig(
        const AutoLapConfig(
          name: 'Config A',
          startDeltaWatts: 150,
          endDeltaWatts: 100,
        ),
      );
      await repo.saveAutoLapConfig(
        const AutoLapConfig(
          name: 'Config B',
          startDeltaWatts: 200,
          endDeltaWatts: 150,
        ),
      );

      final result = await repo.deleteAutoLapConfig(id1);
      expect(result, isTrue);
      final all = await repo.getAutoLapConfigs();
      expect(all.length, 1);
      expect(all.first.name, 'Config B');
    });

    test('promotes another config to default when deleting the default',
        () async {
      final id1 = await repo.saveAutoLapConfig(
        const AutoLapConfig(
          name: 'Alpha',
          startDeltaWatts: 150,
          endDeltaWatts: 100,
          isDefault: true,
        ),
      );
      await repo.saveAutoLapConfig(
        const AutoLapConfig(
          name: 'Beta',
          startDeltaWatts: 200,
          endDeltaWatts: 150,
        ),
      );

      final result = await repo.deleteAutoLapConfig(id1);
      expect(result, isTrue);
      final defaultConfig = await repo.getDefaultConfig();
      expect(defaultConfig.name, 'Beta');
    });

    test('returns false when deleting the last config', () async {
      final id = await repo.saveAutoLapConfig(
        const AutoLapConfig(
          name: 'Only Config',
          startDeltaWatts: 150,
          endDeltaWatts: 100,
        ),
      );

      final result = await repo.deleteAutoLapConfig(id);
      expect(result, isFalse);
      final all = await repo.getAutoLapConfigs();
      expect(all.length, 1);
    });
  });
}
