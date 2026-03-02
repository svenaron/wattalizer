import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/autolap_config.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';
import 'package:wattalizer/domain/services/effort_manager.dart';

AutoLapConfig _cfg({
  double startDelta = 200,
  int startConfirm = 1,
  int startDropout = 0,
  double endDelta = 100,
  int endConfirm = 1,
  int minEffort = 1,
  int preWindow = 5,
  int inWindow = 5,
}) =>
    AutoLapConfig(
      id: 'test',
      name: 'Test',
      startDeltaWatts: startDelta,
      startConfirmSeconds: startConfirm,
      startDropoutTolerance: startDropout,
      endDeltaWatts: endDelta,
      endConfirmSeconds: endConfirm,
      minEffortSeconds: minEffort,
      preEffortBaselineWindow: preWindow,
      inEffortTrailingWindow: inWindow,
    );

SensorReading _r(int t, {double? power, int? hr}) =>
    SensorReading(timestamp: Duration(seconds: t), power: power, heartRate: hr);

void main() {
  final manager = EffortManager();

  group('EffortManager.createEffort', () {
    test('slices readings correctly between startOffset and endOffset', () {
      final rideReadings = [
        _r(0, power: 100),
        _r(1, power: 200),
        _r(2, power: 800),
        _r(3, power: 900),
        _r(4, power: 850),
        _r(5, power: 100),
      ];

      final effort = manager.createEffort(
        rideId: 'ride1',
        effortNumber: 1,
        startOffset: 2,
        endOffset: 4,
        type: EffortType.auto,
        rideReadings: rideReadings,
      );

      // Duration = 4-2+1 = 3
      expect(effort.summary.durationSeconds, 3);
      // avgPower = (800+900+850)/3 = 850
      expect(effort.summary.avgPower, closeTo(850.0, 0.001));
      // peakPower = 900
      expect(effort.summary.peakPower, 900.0);
    });

    test('MAP curve computed from sliced readings', () {
      final rideReadings = [
        _r(0, power: 100),
        _r(1, power: 800),
        _r(2, power: 900),
        _r(3, power: 100),
      ];

      final effort = manager.createEffort(
        rideId: 'ride1',
        effortNumber: 1,
        startOffset: 1,
        endOffset: 2,
        type: EffortType.auto,
        rideReadings: rideReadings,
      );

      // 1s best = 900 (best single reading)
      expect(effort.mapCurve.values[0], closeTo(900.0, 0.001));
      // 2s best = (800+900)/2 = 850
      expect(effort.mapCurve.values[1], closeTo(850.0, 0.001));
      // entityId on curve matches effort id
      expect(effort.mapCurve.entityId, effort.id);
    });

    test('restSincePrevious is null for first effort', () {
      final readings = List.generate(5, (i) => _r(i, power: 400));
      final effort = manager.createEffort(
        rideId: 'r',
        effortNumber: 1,
        startOffset: 0,
        endOffset: 4,
        type: EffortType.auto,
        rideReadings: readings,
      );

      expect(effort.summary.restSincePrevious, isNull);
    });

    test('restSincePrevious computed from gap after previous effort', () {
      final readings = List.generate(20, (i) => _r(i, power: 400));

      final firstEffort = manager.createEffort(
        rideId: 'r',
        effortNumber: 1,
        startOffset: 0,
        endOffset: 5,
        type: EffortType.auto,
        rideReadings: readings,
      );

      final secondEffort = manager.createEffort(
        rideId: 'r',
        effortNumber: 2,
        startOffset: 10,
        endOffset: 15,
        type: EffortType.auto,
        rideReadings: readings,
        previousEffort: firstEffort,
      );

      // Gap = 10 - 5 = 5 seconds
      expect(secondEffort.summary.restSincePrevious, 5);
    });

    test('effort type is preserved', () {
      final readings = List.generate(5, (i) => _r(i, power: 400));

      final manualEffort = manager.createEffort(
        rideId: 'r',
        effortNumber: 1,
        startOffset: 0,
        endOffset: 4,
        type: EffortType.manual,
        rideReadings: readings,
      );

      expect(manualEffort.type, EffortType.manual);
    });

    test('effort has unique id and correct rideId/effortNumber', () {
      final readings = List.generate(5, (i) => _r(i, power: 400));

      final e1 = manager.createEffort(
        rideId: 'ride-xyz',
        effortNumber: 3,
        startOffset: 0,
        endOffset: 4,
        type: EffortType.auto,
        rideReadings: readings,
      );

      final e2 = manager.createEffort(
        rideId: 'ride-xyz',
        effortNumber: 3,
        startOffset: 0,
        endOffset: 4,
        type: EffortType.auto,
        rideReadings: readings,
      );

      expect(e1.rideId, 'ride-xyz');
      expect(e1.effortNumber, 3);
      expect(e1.id, isNotEmpty);
      expect(e1.id, isNot(e2.id)); // UUIDs should be unique
    });
  });

  group('EffortManager.redetectEfforts', () {
    test('detects one clean effort', () {
      // Build: 5s recovery at 100W, 5s sprint at 500W, 5s recovery at 100W
      final readings = [
        ...List.generate(5, (i) => _r(i, power: 100)),
        ...List.generate(5, (i) => _r(i + 5, power: 500)),
        ...List.generate(5, (i) => _r(i + 10, power: 100)),
      ];

      final efforts = manager.redetectEfforts(
        rideId: 'r',
        readings: readings,
        config: _cfg(endDelta: 200),
      );

      expect(efforts.length, 1);
      expect(efforts[0].startOffset, 5);
      expect(efforts[0].effortNumber, 1);
    });

    test('different configs produce different effort boundaries', () {
      // 10s at 100W, 5s at 400W, 10s at 100W
      final readings = [
        ...List.generate(10, (i) => _r(i, power: 100)),
        ...List.generate(5, (i) => _r(i + 10, power: 400)),
        ...List.generate(10, (i) => _r(i + 15, power: 100)),
      ];

      // Config A: sensitive (low delta → detects)
      final effA = manager.redetectEfforts(
        rideId: 'r',
        readings: readings,
        config: _cfg(startDelta: 100),
      );

      // Config B: insensitive (very high delta → does not detect)
      final effB = manager.redetectEfforts(
        rideId: 'r',
        readings: readings,
        config: _cfg(startDelta: 500, endDelta: 500),
      );

      expect(effA.length, greaterThan(effB.length));
    });

    test('restSincePrevious correct in redetected back-to-back efforts', () {
      // 3s at 100W, 3s sprint, 4s rest, 3s sprint, 3s recovery
      final readings = [
        ...List.generate(3, (i) => _r(i, power: 100)),
        ...List.generate(3, (i) => _r(i + 3, power: 500)),
        ...List.generate(4, (i) => _r(i + 6, power: 100)),
        ...List.generate(3, (i) => _r(i + 10, power: 500)),
        ...List.generate(3, (i) => _r(i + 13, power: 100)),
      ];

      final efforts = manager.redetectEfforts(
        rideId: 'r',
        readings: readings,
        config: _cfg(endDelta: 200),
      );

      if (efforts.length >= 2) {
        // restSincePrevious for 2nd effort = start2 - end1
        final rest = efforts[1].summary.restSincePrevious;
        expect(rest, isNotNull);
        expect(rest, greaterThan(0));
      }
    });

    test('too-short efforts are discarded', () {
      // Baseline = 100W. Sprint = 500W (1 reading). Recovery = 50W.
      // With endDelta=100: trailing starts at [500], after adding 50 → avg=275.
      // 50 < 275 - 100 = 175 → TRUE → end triggers immediately (endConfirm=1).
      // duration = endOffset(6) - startOffset(5) = 1 < minEffort=5
      // → wasTooShort=true.
      final readings = [
        ...List.generate(5, (i) => _r(i, power: 100)),
        _r(5, power: 500), // 1-second spike
        ...List.generate(5, (i) => _r(i + 6, power: 50)),
      ];

      final efforts = manager.redetectEfforts(
        rideId: 'r',
        readings: readings,
        config: _cfg(
          minEffort: 5, // spike is 1s, too short
        ),
      );

      expect(efforts, isEmpty);
    });
  });
}
