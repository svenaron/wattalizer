import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/data/tcx/tcx_parser.dart';
import 'package:wattalizer/data/tcx/tcx_serializer.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/effort_summary.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/domain/models/ride_summary.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Ride makeRide(List<Effort> efforts, int readingCount) {
    return Ride(
      id: 'ride-rt',
      startTime: DateTime.utc(2026, 3, 1, 10),
      source: RideSource.recorded,
      efforts: efforts,
      summary: RideSummary(
        durationSeconds: readingCount,
        activeDurationSeconds: 0,
        avgPower: 0,
        maxPower: 0,
        readingCount: readingCount,
        effortCount: efforts.length,
      ),
    );
  }

  Effort makeEffort(int start, int end) {
    return Effort(
      id: 'effort-rt-1',
      rideId: 'ride-rt',
      effortNumber: 1,
      startOffset: start,
      endOffset: end,
      type: EffortType.auto,
      summary: EffortSummary(
        durationSeconds: end - start,
        avgPower: 500,
        peakPower: 800,
      ),
      mapCurve: MapCurve(
        entityId: 'effort-rt-1',
        values: List.filled(90, 500),
        flags: List.generate(90, (_) => const MapCurveFlags()),
        computedAt: DateTime.utc(2026, 3),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Round-trip tests
  // ---------------------------------------------------------------------------

  group('round-trip: serialize → parse', () {
    test('reading count is preserved', () {
      final readings = [
        const SensorReading(timestamp: Duration.zero, power: 1200),
        const SensorReading(timestamp: Duration(seconds: 1)),
        const SensorReading(timestamp: Duration(seconds: 2), power: 0),
        const SensorReading(timestamp: Duration(seconds: 3), power: 350.5),
      ];
      final ride = makeRide([], readings.length);

      final xml = TcxSerializer.serialize(ride, readings);
      final result = TcxParser.parse(xml);

      expect(result.readings.length, readings.length);
    });

    test('null power round-trips as null (dropout omitted → absent)', () {
      final readings = [const SensorReading(timestamp: Duration.zero)];
      final ride = makeRide([], 1);

      final xml = TcxSerializer.serialize(ride, readings);
      final result = TcxParser.parse(xml);

      expect(result.readings[0].power, isNull);
    });

    test('non-null power survives round-trip', () {
      final readings = [
        const SensorReading(timestamp: Duration.zero, power: 1200),
        const SensorReading(timestamp: Duration(seconds: 1), power: 350.5),
      ];
      final ride = makeRide([], 2);

      final xml = TcxSerializer.serialize(ride, readings);
      final result = TcxParser.parse(xml);

      expect(result.readings[0].power, 1200.0);
      expect(result.readings[1].power, 350.5);
    });

    test('power == 0.0 (coasting) survives round-trip', () {
      final readings = [
        const SensorReading(timestamp: Duration.zero, power: 0),
      ];
      final ride = makeRide([], 1);

      final xml = TcxSerializer.serialize(ride, readings);
      final result = TcxParser.parse(xml);

      expect(
        result.readings[0].power,
        0.0,
        reason: 'coasting (0.0) must not be treated as null dropout',
      );
    });

    test('non-null heartRate survives round-trip', () {
      final readings = [
        const SensorReading(timestamp: Duration.zero, heartRate: 172),
      ];
      final ride = makeRide([], 1);

      final xml = TcxSerializer.serialize(ride, readings);
      final result = TcxParser.parse(xml);

      expect(result.readings[0].heartRate, 172);
    });

    test('null heartRate round-trips as null', () {
      final readings = [
        const SensorReading(timestamp: Duration.zero, power: 1000),
      ];
      final ride = makeRide([], 1);

      final xml = TcxSerializer.serialize(ride, readings);
      final result = TcxParser.parse(xml);

      expect(result.readings[0].heartRate, isNull);
    });

    test('non-null cadence survives round-trip (integer-rounded)', () {
      final readings = [
        const SensorReading(timestamp: Duration.zero, cadence: 115),
      ];
      final ride = makeRide([], 1);

      final xml = TcxSerializer.serialize(ride, readings);
      final result = TcxParser.parse(xml);

      // Serializer rounds cadence to int; parser reads back as double
      expect(result.readings[0].cadence, 115.0);
    });

    test('null cadence round-trips as null', () {
      final readings = [
        const SensorReading(timestamp: Duration.zero, power: 1000),
      ];
      final ride = makeRide([], 1);

      final xml = TcxSerializer.serialize(ride, readings);
      final result = TcxParser.parse(xml);

      expect(result.readings[0].cadence, isNull);
    });

    test('startTime is preserved through round-trip', () {
      final readings = [
        const SensorReading(timestamp: Duration.zero, power: 1000),
      ];
      final ride = makeRide([], 1);

      final xml = TcxSerializer.serialize(ride, readings);
      final result = TcxParser.parse(xml);

      expect(result.startTime, ride.startTime.toUtc());
    });

    test('mix of null and non-null fields across multiple readings', () {
      final readings = [
        const SensorReading(
          timestamp: Duration.zero,
          power: 1200,
          heartRate: 168,
          cadence: 100,
        ),
        const SensorReading(timestamp: Duration(seconds: 1), heartRate: 170),
        const SensorReading(
          timestamp: Duration(seconds: 2),
          power: 0, // coasting
          cadence: 95,
        ),
      ];
      final ride = makeRide([], 3);

      final xml = TcxSerializer.serialize(ride, readings);
      final result = TcxParser.parse(xml);

      expect(result.readings.length, 3);

      // Reading 0
      expect(result.readings[0].power, 1200.0);
      expect(result.readings[0].heartRate, 168);
      expect(result.readings[0].cadence, 100.0);

      // Reading 1 — power dropout
      expect(result.readings[1].power, isNull);
      expect(result.readings[1].heartRate, 170);
      expect(result.readings[1].cadence, isNull);

      // Reading 2 — coasting
      expect(result.readings[2].power, 0.0);
      expect(result.readings[2].heartRate, isNull);
      expect(result.readings[2].cadence, 95.0);
    });

    test('effort boundaries survive via effort-based laps', () {
      // Ride with 4 readings, effort covers [2, 4)
      final effort = makeEffort(2, 4);
      final readings = [
        const SensorReading(timestamp: Duration.zero, power: 200),
        const SensorReading(timestamp: Duration(seconds: 1), power: 200),
        const SensorReading(timestamp: Duration(seconds: 2), power: 800),
        const SensorReading(timestamp: Duration(seconds: 3), power: 900),
      ];
      final ride = makeRide([effort], readings.length);

      final xml = TcxSerializer.serialize(ride, readings);
      final result = TcxParser.parse(xml);

      // All 4 readings survive regardless of lap structure
      expect(result.readings.length, 4);
      // Check offsets are correct
      final offsets =
          result.readings.map((r) => r.timestamp.inSeconds).toList();
      expect(offsets, [0, 1, 2, 3]);
    });
  });
}
