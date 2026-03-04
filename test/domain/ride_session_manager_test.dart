import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/events/autolap_events.dart';
import 'package:wattalizer/domain/interfaces/ble_service.dart';
import 'package:wattalizer/domain/interfaces/ride_repository.dart';
import 'package:wattalizer/domain/models/autolap_config.dart';
import 'package:wattalizer/domain/models/device_info.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/domain/models/ride_state.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';
import 'package:wattalizer/domain/services/ride_session_manager.dart';

void main() {
  group('RideSessionManager', () {
    late _FakeRepository repo;
    late AutoLapConfig config;
    late List<RideState> emittedStates;

    // Config with startConfirmSeconds=1 so efforts start immediately.
    setUp(() {
      repo = _FakeRepository();
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
      emittedStates = [];
    });

    RideSessionManager makeManager() => RideSessionManager(
          repository: repo,
          config: config,
          onStateChanged: emittedStates.add,
          enableWakelock: () async {},
          disableWakelock: () async {},
        );

    // -------------------------------------------------------------------------
    // _mergeBin (tested indirectly via processTick → emitted state.readings)
    // -------------------------------------------------------------------------

    group('_mergeBin via processTick', () {
      test('empty bin → all-null SensorReading (dropout)', () {
        final sc = StreamController<RawSensorData>();
        makeManager()
          ..start(sc.stream)

          // No data added — bin is empty
          ..processTick();

        final state = emittedStates.last as RideStateActive;
        final reading = state.readings.last;
        expect(reading.power, isNull);
        expect(reading.heartRate, isNull);
        expect(reading.cadence, isNull);
        unawaited(sc.close());
      });

      test('single reading — power equals the reading', () {
        final sc = StreamController<RawSensorData>();
        final mgr = makeManager()..start(sc.stream);

        mgr.currentBin.add(
          RawSensorData(
            receivedAt: DateTime.now(),
            power: const PowerData(instantaneousPower: 300),
          ),
        );
        mgr.processTick();

        final state = emittedStates.last as RideStateActive;
        expect(state.readings.last.power, 300.0);
      });

      test('power averaged across all non-null values in bin', () {
        final sc = StreamController<RawSensorData>();
        final mgr = makeManager()..start(sc.stream);

        mgr.currentBin
          ..add(
            RawSensorData(
              receivedAt: DateTime.now(),
              power: const PowerData(instantaneousPower: 200),
            ),
          )
          ..add(
            RawSensorData(
              receivedAt: DateTime.now(),
              power: const PowerData(instantaneousPower: 300),
            ),
          )
          ..add(
            RawSensorData(
              receivedAt: DateTime.now(),
              power: const PowerData(instantaneousPower: 400),
            ),
          );
        mgr.processTick();

        final state = emittedStates.last as RideStateActive;
        expect(state.readings.last.power, closeTo(300.0, 0.01));
      });

      test('HR uses last non-null value in bin', () {
        final sc = StreamController<RawSensorData>();
        final mgr = makeManager()..start(sc.stream);

        mgr.currentBin
          ..add(
            RawSensorData(
              receivedAt: DateTime.now(),
              hr: const HeartRateData(heartRate: 150),
            ),
          )
          ..add(
            RawSensorData(
              receivedAt: DateTime.now(),
              hr: const HeartRateData(heartRate: 160),
            ),
          );
        mgr.processTick();

        final state = emittedStates.last as RideStateActive;
        expect(state.readings.last.heartRate, 160);
      });

      test('cadence uses last non-null value in bin', () {
        final sc = StreamController<RawSensorData>();
        final mgr = makeManager()..start(sc.stream);

        mgr.currentBin
          ..add(
            RawSensorData(
              receivedAt: DateTime.now(),
              cadence: const CadenceData(rpm: 90),
            ),
          )
          ..add(
            RawSensorData(
              receivedAt: DateTime.now(),
              cadence: const CadenceData(rpm: 95),
            ),
          );
        mgr.processTick();

        final state = emittedStates.last as RideStateActive;
        expect(state.readings.last.cadence, 95.0);
      });
    });

    // -------------------------------------------------------------------------
    // start()
    // -------------------------------------------------------------------------

    group('start', () {
      test('initializes rideId, startTime; readings and efforts are empty', () {
        final sc = StreamController<RawSensorData>();
        makeManager().start(sc.stream);

        final state = emittedStates.last as RideStateActive;
        expect(state.rideId, isNotEmpty);
        expect(
          state.startTime
              .isBefore(DateTime.now().add(const Duration(seconds: 1))),
          isTrue,
        );
        expect(state.readings, isEmpty);
        expect(state.completedEfforts, isEmpty);
        expect(state.autoLapState, AutoLapState.idle);
        unawaited(sc.close());
      });

      test('emits RideStateActive immediately on start', () {
        final sc = StreamController<RawSensorData>();
        makeManager().start(sc.stream);

        expect(emittedStates, hasLength(1));
        expect(emittedStates.first, isA<RideStateActive>());
        unawaited(sc.close());
      });
    });

    // -------------------------------------------------------------------------
    // processTick
    // -------------------------------------------------------------------------

    group('processTick', () {
      test('each tick adds a reading and increments offset', () {
        final sc = StreamController<RawSensorData>();
        makeManager()
          ..start(sc.stream)
          ..processTick()
          ..processTick()
          ..processTick();

        final state = emittedStates.last as RideStateActive;
        expect(state.readings, hasLength(3));
        expect(state.readings[0].timestamp.inSeconds, 0);
        expect(state.readings[1].timestamp.inSeconds, 1);
        expect(state.readings[2].timestamp.inSeconds, 2);
        unawaited(sc.close());
      });

      test('bin is cleared after each tick', () {
        final sc = StreamController<RawSensorData>();
        final mgr = makeManager()..start(sc.stream);

        mgr.currentBin.add(
          RawSensorData(
            receivedAt: DateTime.now(),
            power: const PowerData(instantaneousPower: 300),
          ),
        );
        mgr.processTick();
        expect(mgr.currentBin, isEmpty);
        unawaited(sc.close());
      });

      test('live curve created on EffortStartedEvent', () {
        final sc = StreamController<RawSensorData>();
        final mgr = makeManager()..start(sc.stream);

        // Build baseline (5 ticks at 100W to prime baseline window)
        for (var i = 0; i < 5; i++) {
          mgr.currentBin.add(
            RawSensorData(
              receivedAt: DateTime.now(),
              power: const PowerData(instantaneousPower: 100),
            ),
          );
          mgr.processTick();
        }

        // Spike above threshold
        // (100 + 200 = 300W → effort starts with confirm=1)
        mgr.currentBin.add(
          RawSensorData(
            receivedAt: DateTime.now(),
            power: const PowerData(instantaneousPower: 350),
          ),
        );
        mgr.processTick();

        final state = emittedStates.last as RideStateActive;
        expect(state.autoLapState, AutoLapState.inEffort);
        expect(state.liveEffortCurve, isNotNull);
      });

      test('live curve 1s value is not double-counted on effort start', () {
        final sc = StreamController<RawSensorData>();
        final mgr = makeManager()..start(sc.stream);

        // Build baseline (5 ticks at 100W)
        for (var i = 0; i < 5; i++) {
          mgr.currentBin.add(
            RawSensorData(
              receivedAt: DateTime.now(),
              power: const PowerData(instantaneousPower: 100),
            ),
          );
          mgr.processTick();
        }

        // Spike that triggers effort start (confirm=1)
        mgr.currentBin.add(
          RawSensorData(
            receivedAt: DateTime.now(),
            power: const PowerData(instantaneousPower: 350),
          ),
        );
        mgr.processTick();

        final state = emittedStates.last as RideStateActive;
        expect(state.liveEffortCurve, isNotNull);
        // 1-second best power should be 350, not 700 (double-feed bug)
        expect(state.liveEffortCurve!.values[0], 350.0);
        unawaited(sc.close());
      });
    });

    // -------------------------------------------------------------------------
    // _handleEvent
    // -------------------------------------------------------------------------

    group('_handleEvent', () {
      test('EffortEndedEvent valid → Effort added to completedEfforts', () {
        final sc = StreamController<RawSensorData>();
        final mgr = makeManager()..start(sc.stream);

        // Build baseline
        for (var i = 0; i < 5; i++) {
          mgr.currentBin.add(
            RawSensorData(
              receivedAt: DateTime.now(),
              power: const PowerData(instantaneousPower: 100),
            ),
          );
          mgr.processTick();
        }

        // Sprint: 5 ticks at 350W (≥ minEffortSeconds=2)
        for (var i = 0; i < 5; i++) {
          mgr.currentBin.add(
            RawSensorData(
              receivedAt: DateTime.now(),
              power: const PowerData(instantaneousPower: 350),
            ),
          );
          mgr.processTick();
        }

        // Drop below end threshold (350 - 100 = 250, need < 250W)
        for (var i = 0; i < 2; i++) {
          mgr.currentBin.add(
            RawSensorData(
              receivedAt: DateTime.now(),
              power: const PowerData(instantaneousPower: 50),
            ),
          );
          mgr.processTick();
        }

        final state = emittedStates.last as RideStateActive;
        expect(state.completedEfforts, hasLength(1));
        expect(state.liveEffortCurve, isNull);
      });

      test('EffortEndedEvent wasTooShort → effort discarded', () {
        // Config with minEffortSeconds=10 so short bursts are discarded
        final strictConfig = config.copyWith(minEffortSeconds: 10);
        final sc = StreamController<RawSensorData>();
        final mgr = RideSessionManager(
          repository: repo,
          config: strictConfig,
          onStateChanged: emittedStates.add,
          enableWakelock: () async {},
          disableWakelock: () async {},
        )..start(sc.stream);

        // Build baseline
        for (var i = 0; i < 5; i++) {
          mgr.currentBin.add(
            RawSensorData(
              receivedAt: DateTime.now(),
              power: const PowerData(instantaneousPower: 100),
            ),
          );
          mgr.processTick();
        }

        // Short burst (2 ticks = too short for minEffortSeconds=10)
        for (var i = 0; i < 2; i++) {
          mgr.currentBin.add(
            RawSensorData(
              receivedAt: DateTime.now(),
              power: const PowerData(instantaneousPower: 350),
            ),
          );
          mgr.processTick();
        }

        // Drop
        mgr.currentBin.add(
          RawSensorData(
            receivedAt: DateTime.now(),
            power: const PowerData(instantaneousPower: 50),
          ),
        );
        mgr.processTick();

        final state = emittedStates.last as RideStateActive;
        expect(state.completedEfforts, isEmpty);
        unawaited(sc.close());
      });
    });

    // -------------------------------------------------------------------------
    // manualLap
    // -------------------------------------------------------------------------

    group('manualLap', () {
      test('in idle → starts an effort, emits state', () {
        final sc = StreamController<RawSensorData>();
        final mgr = makeManager()..start(sc.stream);

        final statesBefore = emittedStates.length;
        mgr.manualLap();

        expect(emittedStates.length, greaterThan(statesBefore));
        final state = emittedStates.last as RideStateActive;
        expect(state.autoLapState, AutoLapState.inEffort);
        unawaited(sc.close());
      });

      test('in inEffort → ends current effort and starts new one', () {
        final sc = StreamController<RawSensorData>();
        final mgr = makeManager()
          ..start(sc.stream)

          // Start an effort manually and add a tick to have some readings
          ..manualLap();
        mgr.currentBin.add(
          RawSensorData(
            receivedAt: DateTime.now(),
            power: const PowerData(instantaneousPower: 300),
          ),
        );
        mgr
          ..processTick()

          // End it and start a new one
          ..manualLap();

        final state = emittedStates.last as RideStateActive;
        expect(state.completedEfforts, hasLength(1));
        expect(state.autoLapState, AutoLapState.inEffort);
        unawaited(sc.close());
      });
    });

    // -------------------------------------------------------------------------
    // end()
    // -------------------------------------------------------------------------

    group('end', () {
      test('returns Ride with source=recorded', () async {
        final sc = StreamController<RawSensorData>();
        final mgr = makeManager()..start(sc.stream);

        // Add a few ticks
        for (var i = 0; i < 3; i++) {
          mgr.currentBin.add(
            RawSensorData(
              receivedAt: DateTime.now(),
              power: const PowerData(instantaneousPower: 200),
            ),
          );
          mgr.processTick();
        }

        final ride = await mgr.end();

        expect(ride.source, RideSource.recorded);
        expect(ride.autoLapConfigId, config.id);
        expect(ride.endTime, isNotNull);
      });

      test('persists ride, readings, efforts, and map curves in transaction',
          () async {
        final sc = StreamController<RawSensorData>();
        final mgr = makeManager()..start(sc.stream);

        // Tick a few times with power readings
        for (var i = 0; i < 3; i++) {
          mgr.currentBin.add(
            RawSensorData(
              receivedAt: DateTime.now(),
              power: const PowerData(instantaneousPower: 200),
            ),
          );
          mgr.processTick();
        }

        await mgr.end();

        expect(repo.transactionCount, greaterThan(0));
        expect(repo.savedRides, hasLength(1));
        expect(repo.insertedReadings, hasLength(3));
      });

      test('finalizes in-progress effort on end', () async {
        final sc = StreamController<RawSensorData>();
        final mgr = makeManager()
          ..start(sc.stream)

          // Manually start an effort
          ..manualLap();

        // Add readings
        for (var i = 0; i < 5; i++) {
          mgr.currentBin.add(
            RawSensorData(
              receivedAt: DateTime.now(),
              power: const PowerData(instantaneousPower: 300),
            ),
          );
          mgr.processTick();
        }

        final ride = await mgr.end();
        expect(ride.efforts, hasLength(1));
      });
    });
  });
}

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

class _FakeRepository implements RideRepository {
  final List<Ride> savedRides = [];
  final Map<String, List<SensorReading>> insertedReadingsByRide = {};
  final Map<String, List<Effort>> savedEffortsByRide = {};
  final Map<String, MapCurve> savedCurves = {};
  int transactionCount = 0;

  List<SensorReading> get insertedReadings =>
      insertedReadingsByRide.values.expand((l) => l).toList();

  @override
  Future<void> transaction(Future<void> Function() work) async {
    transactionCount++;
    await work();
  }

  @override
  Future<void> saveRide(Ride ride) async => savedRides.add(ride);

  @override
  Future<void> updateRide(Ride ride) async {}

  @override
  Future<Ride?> getRide(String id) async => null;

  @override
  Future<List<RideSummaryRow>> getRides({
    DateTime? from,
    DateTime? to,
    Set<String>? tags,
    int? limit,
    int offset = 0,
  }) async =>
      [];

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
  ) async {
    insertedReadingsByRide[rideId] = readings;
  }

  @override
  Future<List<Effort>> getEfforts(String rideId) async => [];

  @override
  Future<void> saveEfforts(String rideId, List<Effort> efforts) async {
    savedEffortsByRide[rideId] = efforts;
  }

  @override
  Future<void> deleteEfforts(String rideId) async {}

  @override
  Future<void> saveMapCurve(String entityId, MapCurve curve) async {
    savedCurves[entityId] = curve;
  }

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
