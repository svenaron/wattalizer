import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/core/error_types.dart';
import 'package:wattalizer/domain/interfaces/ride_repository.dart';
import 'package:wattalizer/domain/models/autolap_config.dart';
import 'package:wattalizer/domain/models/device_info.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/domain/models/ride_summary.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';
import 'package:wattalizer/domain/services/export_service.dart';

void main() {
  late Directory tempDir;
  late AutoLapConfig config;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('export_service_test_');
    config = const AutoLapConfig(
      id: 'test',
      name: 'Test',
      startDeltaWatts: 200,
      startConfirmSeconds: 1,
      startDropoutTolerance: 0,
      endDeltaWatts: 100,
      endConfirmSeconds: 1,
      minEffortSeconds: 2,
      preEffortBaselineWindow: 5,
      inEffortTrailingWindow: 5,
    );
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  ExportService makeService({List<RideSummaryRow> existingRides = const []}) =>
      ExportService(
        repository: _FakeRepository(rides: existingRides),
        exportDirectory: tempDir,
      );

  // ---------------------------------------------------------------------------
  // exportTcx
  // ---------------------------------------------------------------------------

  group('exportTcx', () {
    test('returns a .tcx path and file contains valid TCX content', () async {
      final ride = _makeRide('r1');
      final readings = _makeReadings(count: 5, startPower: 200);
      final svc = makeService();

      final path = await svc.exportTcx(ride, readings);

      expect(path, endsWith('.tcx'));
      final content = File(path).readAsStringSync();
      expect(content, contains('<TrainingCenterDatabase'));
      // TCX uses startTime as the Activity Id, file named by ride.id
      expect(path, contains('r1'));
      expect(content, contains('2024-01-15'));
    });

    test('file is written inside the injected export directory', () async {
      final ride = _makeRide('r2');
      final svc = makeService();

      final path = await svc.exportTcx(ride, []);

      expect(File(path).existsSync(), isTrue);
      expect(path, startsWith(tempDir.path));
    });
  });

  // ---------------------------------------------------------------------------
  // importTcx — success
  // ---------------------------------------------------------------------------

  group('importTcx success', () {
    test(
      'valid TCX → Ride with importedTcx source and correct startTime',
      () async {
        final svc = makeService();
        final file = _writeTcxFile(tempDir, _validTcx());

        final ride = await svc.importTcx(file, config);

        expect(ride.source, RideSource.importedTcx);
        // startTime comes from the TCX file
        expect(ride.startTime.toUtc().year, 2024);
      },
    );

    test(
      'valid TCX → readings re-detected into efforts when above threshold',
      () async {
        // Config with low threshold so all power readings form an effort
        const lowConfig = AutoLapConfig(
          id: 'low',
          name: 'Low',
          startDeltaWatts: 50,
          startConfirmSeconds: 1,
          startDropoutTolerance: 0,
          endDeltaWatts: 50,
          endConfirmSeconds: 1,
          minEffortSeconds: 2,
          preEffortBaselineWindow: 2,
          inEffortTrailingWindow: 2,
        );
        final svc = makeService();
        final file = _writeTcxFile(tempDir, _validTcxWithSpike());

        final ride = await svc.importTcx(file, lowConfig);

        // We just check that the import succeeds and ride is populated
        expect(ride.id, isNotEmpty);
        expect(ride.summary.readingCount, greaterThan(0));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // importTcx — errors
  // ---------------------------------------------------------------------------

  group('importTcx errors', () {
    test('malformed XML → TcxImportError.malformedXml', () async {
      final svc = makeService();
      final file = File('${tempDir.path}/bad.tcx')
        ..writeAsStringSync('<not valid xml <<<');

      expect(
        () => svc.importTcx(file, config),
        throwsA(
          isA<TcxImportError>().having(
            (e) => e.type,
            'type',
            ImportErrorType.malformedXml,
          ),
        ),
      );
    });

    test('valid XML but no trackpoints → noTrackpoints', () async {
      const emptyXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<TrainingCenterDatabase
    xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2">
  <Activities>
    <Activity Sport="Biking">
      <Id>2024-01-15T10:00:00Z</Id>
    </Activity>
  </Activities>
</TrainingCenterDatabase>''';
      final svc = makeService();
      final file = File('${tempDir.path}/empty.tcx')
        ..writeAsStringSync(emptyXml);

      expect(
        () => svc.importTcx(file, config),
        throwsA(
          isA<TcxImportError>().having(
            (e) => e.type,
            'type',
            ImportErrorType.noTrackpoints,
          ),
        ),
      );
    });

    test('trackpoints present but no power data → noPowerData', () async {
      final svc = makeService();
      final file = _writeTcxFile(tempDir, _tcxNoPower());

      expect(
        () => svc.importTcx(file, config),
        throwsA(
          isA<TcxImportError>().having(
            (e) => e.type,
            'type',
            ImportErrorType.noPowerData,
          ),
        ),
      );
    });

    test('file > 50MB → fileTooLarge', () async {
      final svc = makeService();
      // Create a file larger than 50MB
      final bigFile = File('${tempDir.path}/big.tcx');
      final sink = bigFile.openWrite();
      final chunk = List.filled(1024 * 1024, 0x61); // 'a' × 1MB
      for (var i = 0; i < 51; i++) {
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();

      expect(
        () => svc.importTcx(bigFile, config),
        throwsA(
          isA<TcxImportError>().having(
            (e) => e.type,
            'type',
            ImportErrorType.fileTooLarge,
          ),
        ),
      );
    });

    test('duplicate startTime and readingCount → duplicateRide', () async {
      final startTime = DateTime.utc(2024, 1, 15, 10);
      // The TCX will have 5 trackpoints; fake a matching existing ride
      final existing = _makeSummaryRow(
        startTime: startTime.subtract(const Duration(milliseconds: 500)),
        readingCount: 5,
      );
      final svc = makeService(existingRides: [existing]);
      final file = _writeTcxFile(tempDir, _validTcx());

      expect(
        () => svc.importTcx(file, config),
        throwsA(
          isA<TcxImportError>().having(
            (e) => e.type,
            'type',
            ImportErrorType.duplicateRide,
          ),
        ),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // importZip
  // ---------------------------------------------------------------------------

  group('importZip', () {
    test('ZIP with 2 valid TCX files → 2 successful ImportResults', () async {
      final svc = makeService();
      final zipFile = _makeZip(tempDir, {
        'ride1.tcx': _validTcx(),
        'ride2.tcx': _validTcxWithSpike(),
      });

      final results = await svc.importZip(zipFile, config);

      expect(results, hasLength(2));
      expect(results.every((r) => r.error == null), isTrue);
      expect(results.every((r) => r.ride != null), isTrue);
    });

    test('ZIP with one bad file → 1 success + 1 failure', () async {
      final svc = makeService();
      final zipFile = _makeZip(tempDir, {
        'good.tcx': _validTcx(),
        'bad.tcx': 'not xml at all <<<',
      });

      final results = await svc.importZip(zipFile, config);

      expect(results, hasLength(2));
      final successes = results.where((r) => r.ride != null).toList();
      final failures = results.where((r) => r.error != null).toList();
      expect(successes, hasLength(1));
      expect(failures, hasLength(1));
    });

    test('ZIP with file in subdirectory → 1 successful ImportResult', () async {
      final svc = makeService();
      final zipFile = _makeZipWithBytes(tempDir, {
        'activities/ride.tcx': _validTcx().codeUnits,
      });

      final results = await svc.importZip(zipFile, config);

      expect(results, hasLength(1));
      expect(results.first.ride, isNotNull);
    });

    test('ZIP with .tcx.gz file → 1 successful ImportResult', () async {
      final svc = makeService();
      final gzBytes = const GZipEncoder().encode(_validTcx().codeUnits);
      final zipFile = _makeZipWithBytes(tempDir, {
        'activities/ride.tcx.gz': gzBytes,
      });

      final results = await svc.importZip(zipFile, config);

      expect(results, hasLength(1));
      expect(results.first.ride, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Timezone
  // ---------------------------------------------------------------------------

  group('timezone', () {
    test('TCX with +02:00 offset → startTime stored as UTC', () async {
      final svc = makeService();
      final file = _writeTcxFile(tempDir, _tcxWithOffset());

      final ride = await svc.importTcx(file, config);

      // 2024-01-15T12:00:00+02:00 = 2024-01-15T10:00:00Z
      expect(ride.startTime.isUtc, isTrue);
      expect(ride.startTime.hour, 10);
    });
  });

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  group('persistence', () {
    test('importTcx calls saveRide and insertReadings on success', () async {
      final repo = _TrackingRepository();
      final svc = ExportService(repository: repo, exportDirectory: tempDir);
      final file = _writeTcxFile(tempDir, _validTcx());

      await svc.importTcx(file, config);

      expect(repo.saveRideCalls, 1);
      expect(repo.insertReadingsCalls, 1);
    });

    test('importZip calls onProgress with (0,n)…(n,n) for n valid files',
        () async {
      final svc = makeService();
      final zipFile = _makeZip(tempDir, {
        'ride1.tcx': _validTcx(),
        'ride2.tcx': _validTcxWithSpike(),
      });

      final progress = <(int, int)>[];
      await svc.importZip(
        zipFile,
        config,
        onProgress: (done, total) => progress.add((done, total)),
      );

      expect(progress, [(0, 2), (1, 2), (2, 2)]);
    });
  });
}

// =============================================================================
// TCX fixtures
// =============================================================================

String _validTcx() => '''
<?xml version="1.0" encoding="UTF-8"?>
<TrainingCenterDatabase
    xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2"
    xmlns:ns3="http://www.garmin.com/xmlschemas/ActivityExtension/v2">
  <Activities>
    <Activity Sport="Biking">
      <Id>2024-01-15T10:00:00Z</Id>
      <Lap StartTime="2024-01-15T10:00:00Z">
        <TotalTimeSeconds>5</TotalTimeSeconds>
        <Track>
          <Trackpoint>
            <Time>2024-01-15T10:00:00Z</Time>
            <Extensions>
              <ns3:TPX><ns3:Watts>300.0</ns3:Watts></ns3:TPX>
            </Extensions>
          </Trackpoint>
          <Trackpoint>
            <Time>2024-01-15T10:00:01Z</Time>
            <Extensions>
              <ns3:TPX><ns3:Watts>310.0</ns3:Watts></ns3:TPX>
            </Extensions>
          </Trackpoint>
          <Trackpoint>
            <Time>2024-01-15T10:00:02Z</Time>
            <Extensions>
              <ns3:TPX><ns3:Watts>320.0</ns3:Watts></ns3:TPX>
            </Extensions>
          </Trackpoint>
          <Trackpoint>
            <Time>2024-01-15T10:00:03Z</Time>
            <Extensions>
              <ns3:TPX><ns3:Watts>315.0</ns3:Watts></ns3:TPX>
            </Extensions>
          </Trackpoint>
          <Trackpoint>
            <Time>2024-01-15T10:00:04Z</Time>
            <Extensions>
              <ns3:TPX><ns3:Watts>305.0</ns3:Watts></ns3:TPX>
            </Extensions>
          </Trackpoint>
        </Track>
      </Lap>
    </Activity>
  </Activities>
</TrainingCenterDatabase>''';

String _validTcxWithSpike() => '''
<?xml version="1.0" encoding="UTF-8"?>
<TrainingCenterDatabase
    xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2"
    xmlns:ns3="http://www.garmin.com/xmlschemas/ActivityExtension/v2">
  <Activities>
    <Activity Sport="Biking">
      <Id>2024-01-15T11:00:00Z</Id>
      <Lap StartTime="2024-01-15T11:00:00Z">
        <Track>
          <Trackpoint>
            <Time>2024-01-15T11:00:00Z</Time>
            <Extensions><ns3:TPX><ns3:Watts>100.0</ns3:Watts></ns3:TPX></Extensions>
          </Trackpoint>
          <Trackpoint>
            <Time>2024-01-15T11:00:01Z</Time>
            <Extensions><ns3:TPX><ns3:Watts>100.0</ns3:Watts></ns3:TPX></Extensions>
          </Trackpoint>
          <Trackpoint>
            <Time>2024-01-15T11:00:02Z</Time>
            <Extensions><ns3:TPX><ns3:Watts>400.0</ns3:Watts></ns3:TPX></Extensions>
          </Trackpoint>
          <Trackpoint>
            <Time>2024-01-15T11:00:03Z</Time>
            <Extensions><ns3:TPX><ns3:Watts>420.0</ns3:Watts></ns3:TPX></Extensions>
          </Trackpoint>
          <Trackpoint>
            <Time>2024-01-15T11:00:04Z</Time>
            <Extensions><ns3:TPX><ns3:Watts>410.0</ns3:Watts></ns3:TPX></Extensions>
          </Trackpoint>
        </Track>
      </Lap>
    </Activity>
  </Activities>
</TrainingCenterDatabase>''';

String _tcxNoPower() => '''
<?xml version="1.0" encoding="UTF-8"?>
<TrainingCenterDatabase
    xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2">
  <Activities>
    <Activity Sport="Biking">
      <Id>2024-01-15T10:00:00Z</Id>
      <Lap StartTime="2024-01-15T10:00:00Z">
        <Track>
          <Trackpoint>
            <Time>2024-01-15T10:00:00Z</Time>
            <HeartRateBpm><Value>150</Value></HeartRateBpm>
          </Trackpoint>
          <Trackpoint>
            <Time>2024-01-15T10:00:01Z</Time>
            <HeartRateBpm><Value>155</Value></HeartRateBpm>
          </Trackpoint>
        </Track>
      </Lap>
    </Activity>
  </Activities>
</TrainingCenterDatabase>''';

String _tcxWithOffset() => '''
<?xml version="1.0" encoding="UTF-8"?>
<TrainingCenterDatabase
    xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2"
    xmlns:ns3="http://www.garmin.com/xmlschemas/ActivityExtension/v2">
  <Activities>
    <Activity Sport="Biking">
      <Id>2024-01-15T12:00:00+02:00</Id>
      <Lap StartTime="2024-01-15T12:00:00+02:00">
        <Track>
          <Trackpoint>
            <Time>2024-01-15T12:00:00+02:00</Time>
            <Extensions><ns3:TPX><ns3:Watts>300.0</ns3:Watts></ns3:TPX></Extensions>
          </Trackpoint>
          <Trackpoint>
            <Time>2024-01-15T12:00:01+02:00</Time>
            <Extensions><ns3:TPX><ns3:Watts>310.0</ns3:Watts></ns3:TPX></Extensions>
          </Trackpoint>
          <Trackpoint>
            <Time>2024-01-15T12:00:02+02:00</Time>
            <Extensions><ns3:TPX><ns3:Watts>305.0</ns3:Watts></ns3:TPX></Extensions>
          </Trackpoint>
        </Track>
      </Lap>
    </Activity>
  </Activities>
</TrainingCenterDatabase>''';

// =============================================================================
// File helpers
// =============================================================================

File _writeTcxFile(Directory dir, String xml) {
  final file = File('${dir.path}/${DateTime.now().microsecondsSinceEpoch}.tcx')
    ..writeAsStringSync(xml);
  return file;
}

File _makeZip(Directory dir, Map<String, String> entries) {
  final archive = Archive();
  for (final entry in entries.entries) {
    final bytes = entry.value.codeUnits;
    archive.addFile(ArchiveFile(entry.key, bytes.length, bytes));
  }
  final zipBytes = ZipEncoder().encode(archive);
  return File('${dir.path}/test.zip')..writeAsBytesSync(zipBytes);
}

File _makeZipWithBytes(Directory dir, Map<String, List<int>> entries) {
  final archive = Archive();
  for (final entry in entries.entries) {
    archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
  }
  final zipBytes = ZipEncoder().encode(archive);
  return File('${dir.path}/test_bytes.zip')..writeAsBytesSync(zipBytes);
}

// =============================================================================
// Domain helpers
// =============================================================================

Ride _makeRide(String id) => Ride(
      id: id,
      startTime: DateTime.utc(2024, 1, 15, 10),
      source: RideSource.recorded,
      summary: const RideSummary(
        durationSeconds: 60,
        activeDurationSeconds: 30,
        avgPower: 300,
        maxPower: 400,
        readingCount: 60,
        effortCount: 1,
      ),
    );

List<SensorReading> _makeReadings({
  required int count,
  double startPower = 300,
}) =>
    List.generate(
      count,
      (i) => SensorReading(
        timestamp: Duration(seconds: i),
        power: startPower + i,
      ),
    );

RideSummaryRow _makeSummaryRow({
  required DateTime startTime,
  required int readingCount,
}) =>
    RideSummaryRow(
      id: 'existing',
      startTime: startTime,
      tags: const [],
      summary: RideSummary(
        durationSeconds: readingCount,
        activeDurationSeconds: readingCount,
        avgPower: 300,
        maxPower: 400,
        readingCount: readingCount,
        effortCount: 1,
      ),
    );

// =============================================================================
// Tracking repository (records call counts for persistence assertions)
// =============================================================================

class _TrackingRepository extends _FakeRepository {
  int saveRideCalls = 0;
  int insertReadingsCalls = 0;

  @override
  Future<void> saveRide(Ride ride) async => saveRideCalls++;

  @override
  Future<void> insertReadings(
    String rideId,
    List<SensorReading> readings,
  ) async =>
      insertReadingsCalls++;
}

// =============================================================================
// Fake repository
// =============================================================================

class _FakeRepository implements RideRepository {
  _FakeRepository({List<RideSummaryRow> rides = const []}) : _rides = rides;
  final List<RideSummaryRow> _rides;

  @override
  Future<int> getRideCount() async => _rides.length;

  @override
  Future<void> transaction(Future<void> Function() work) async => work();

  @override
  Future<List<RideSummaryRow>> getRides({
    DateTime? from,
    DateTime? to,
    Set<String>? tags,
    int? limit,
    int offset = 0,
  }) async {
    return _rides.where((r) {
      if (from != null && r.startTime.isBefore(from)) return false;
      if (to != null && r.startTime.isAfter(to)) return false;
      return true;
    }).toList();
  }

  @override
  Future<void> saveRide(Ride ride) async {}
  @override
  Future<void> updateRide(Ride ride) async {}
  @override
  Future<Ride?> getRide(String id) async => null;
  @override
  Future<void> deleteRide(String id) async {}
  @override
  Future<List<SensorReading>> getReadings(
    String rideId, {
    int? startOffset,
    int? endOffset,
  }) async =>
      [];
  @override
  Future<void> insertReadings(
    String rideId,
    List<SensorReading> readings,
  ) async {}
  @override
  Future<List<Effort>> getEfforts(String rideId) async => [];
  @override
  Future<void> saveEfforts(String rideId, List<Effort> efforts) async {}
  @override
  Future<void> deleteEfforts(String rideId) async {}
  @override
  Future<void> saveMapCurve(String entityId, MapCurve curve) async {}
  @override
  Future<MapCurve?> getMapCurve(String entityId) async => null;
  @override
  Future<List<MapCurve>> getMapCurvesForRide(String rideId) async => [];
  @override
  Future<List<MapCurveWithProvenance>> getAllEffortCurves({
    DateTime? from,
    DateTime? to,
    Set<String>? tags,
  }) async =>
      [];
  @override
  Future<List<String>> getAllTags() async => [];
  @override
  Future<void> saveRidePdc(String rideId, MapCurve curve) async {}
  @override
  Future<MapCurve?> getRidePdc(String rideId) async => null;
  @override
  Future<List<AutoLapConfig>> getAutoLapConfigs() async => [];
  @override
  Future<AutoLapConfig> getDefaultConfig() async => const AutoLapConfig(
        id: 'default',
        name: 'Default',
        startDeltaWatts: 200,
        endDeltaWatts: 100,
      );
  @override
  Future<void> saveAutoLapConfig(AutoLapConfig config) async {}
  @override
  Future<List<DeviceInfo>> getRememberedDevices() async => [];
  @override
  Future<void> saveDevice(DeviceInfo device) async {}
  @override
  Future<void> deleteDevice(String deviceId) async {}
  @override
  Future<List<DeviceInfo>> getAutoConnectDevices() async => [];
}
