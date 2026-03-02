import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/data/tcx/tcx_serializer.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/effort_summary.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/domain/models/ride_summary.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';
import 'package:xml/xml.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Ride makeRide({required List<Effort> efforts, int readingCount = 6}) {
    return Ride(
      id: 'ride-1',
      startTime: DateTime.utc(2026, 2, 28, 8, 41),
      source: RideSource.recorded,
      efforts: efforts,
      summary: RideSummary(
        durationSeconds: readingCount,
        activeDurationSeconds:
            efforts.fold(0, (sum, e) => sum + (e.endOffset - e.startOffset)),
        avgPower: 1200,
        maxPower: 1380,
        totalKilojoules: 3.6,
        readingCount: readingCount,
        effortCount: efforts.length,
      ),
    );
  }

  Effort makeEffort(int number, int start, int end) {
    return Effort(
      id: 'effort-$number',
      rideId: 'ride-1',
      effortNumber: number,
      startOffset: start,
      endOffset: end,
      type: EffortType.auto,
      summary: EffortSummary(
        durationSeconds: end - start,
        avgPower: 1200,
        peakPower: 1380,
        totalKilojoules: 3.6,
      ),
      mapCurve: MapCurve(
        entityId: 'effort-$number',
        values: List.filled(90, 1200),
        flags: List.generate(90, (_) => const MapCurveFlags()),
        computedAt: DateTime.utc(2026, 2, 28),
      ),
    );
  }

  SensorReading reading(
    int offset, {
    double? power = 1000.0,
    int? heartRate = 160,
    double? cadence = 100.0,
  }) {
    return SensorReading(
      timestamp: Duration(seconds: offset),
      power: power,
      heartRate: heartRate,
      cadence: cadence,
    );
  }

  // 6 readings: offsets 0,1,2,3,4,5
  // effort1: [2,3)  effort2: [5,6)
  // Expected laps: Resting[0,1], Active[2], Resting[3,4], Active[5]
  final effort1 = makeEffort(1, 2, 3);
  final effort2 = makeEffort(2, 5, 6);
  final readings = [
    reading(0),
    reading(1),
    reading(2),
    reading(3),
    reading(4),
    reading(5),
  ];

  // ---------------------------------------------------------------------------
  // Lap structure
  // ---------------------------------------------------------------------------

  group('lap count and structure', () {
    test('2 efforts + 6 readings produces 4 laps', () {
      final ride = makeRide(efforts: [effort1, effort2]);
      final xml = TcxSerializer.serialize(ride, readings);
      final doc = XmlDocument.parse(xml);

      final laps = doc.findAllElements('Lap').toList();
      expect(laps.length, 4, reason: 'rest + active + rest + active');
    });

    test('first and third laps are Resting', () {
      final ride = makeRide(efforts: [effort1, effort2]);
      final xml = TcxSerializer.serialize(ride, readings);
      final doc = XmlDocument.parse(xml);
      final laps = doc.findAllElements('Lap').toList();

      final intensities =
          laps.map((l) => l.getElement('Intensity')?.innerText).toList();
      expect(intensities, ['Resting', 'Active', 'Resting', 'Active']);
    });

    test('active lap has effort readings, resting lap has gap readings', () {
      final ride = makeRide(efforts: [effort1, effort2]);
      final xml = TcxSerializer.serialize(ride, readings);
      final doc = XmlDocument.parse(xml);
      final laps = doc.findAllElements('Lap').toList();

      // Resting lap #1 (index 0): readings at offsets 0, 1
      final restingTrackpoints1 =
          laps[0].findAllElements('Trackpoint').toList();
      expect(restingTrackpoints1.length, 2);

      // Active lap #1 (index 1): reading at offset 2
      final activeTrackpoints1 = laps[1].findAllElements('Trackpoint').toList();
      expect(activeTrackpoints1.length, 1);

      // Resting lap #2 (index 2): readings at offsets 3, 4
      final restingTrackpoints2 =
          laps[2].findAllElements('Trackpoint').toList();
      expect(restingTrackpoints2.length, 2);

      // Active lap #2 (index 3): reading at offset 5
      final activeTrackpoints2 = laps[3].findAllElements('Trackpoint').toList();
      expect(activeTrackpoints2.length, 1);
    });

    test('no efforts produces a single Active lap', () {
      final ride = makeRide(efforts: []);
      final xml = TcxSerializer.serialize(ride, readings);
      final doc = XmlDocument.parse(xml);

      final laps = doc.findAllElements('Lap').toList();
      expect(laps.length, 1);
      expect(laps.first.getElement('Intensity')?.innerText, 'Active');
    });
  });

  // ---------------------------------------------------------------------------
  // Null handling
  // ---------------------------------------------------------------------------

  group('null field omission', () {
    test('power == null → no Extensions or Watts element', () {
      final ride = makeRide(efforts: []);
      final nullPowerReading = [
        const SensorReading(
          timestamp: Duration.zero,
          heartRate: 160,
          cadence: 100,
        ),
      ];
      final xml = TcxSerializer.serialize(ride, nullPowerReading);
      final doc = XmlDocument.parse(xml);

      final tp = doc.findAllElements('Trackpoint').first;
      final hasWatts = tp.descendants
          .whereType<XmlElement>()
          .any((e) => e.name.local == 'Watts');
      expect(
        hasWatts,
        false,
        reason: 'null power (dropout) must not produce a Watts element',
      );
    });

    test('heartRate == null → no HeartRateBpm element', () {
      final ride = makeRide(efforts: []);
      final noHrReading = [
        const SensorReading(
          timestamp: Duration.zero,
          power: 1200,
          cadence: 100,
        ),
      ];
      final xml = TcxSerializer.serialize(ride, noHrReading);
      final doc = XmlDocument.parse(xml);

      final tp = doc.findAllElements('Trackpoint').first;
      expect(tp.getElement('HeartRateBpm'), isNull);
    });

    test('cadence == null → no Cadence element', () {
      final ride = makeRide(efforts: []);
      final noCadReading = [
        const SensorReading(
          timestamp: Duration.zero,
          power: 1200,
          heartRate: 160,
        ),
      ];
      final xml = TcxSerializer.serialize(ride, noCadReading);
      final doc = XmlDocument.parse(xml);

      final tp = doc.findAllElements('Trackpoint').first;
      expect(tp.getElement('Cadence'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Coasting (power == 0.0)
  // ---------------------------------------------------------------------------

  group('coasting power', () {
    test('power == 0.0 → Watts element present with value 0.0', () {
      final ride = makeRide(efforts: []);
      final coastingReading = [
        const SensorReading(
          timestamp: Duration.zero,
          power: 0,
        ),
      ];
      final xml = TcxSerializer.serialize(ride, coastingReading);
      final doc = XmlDocument.parse(xml);

      final tp = doc.findAllElements('Trackpoint').first;
      final wattsEl = tp.descendants
          .whereType<XmlElement>()
          .firstWhere((e) => e.name.local == 'Watts');
      expect(
        wattsEl.innerText,
        '0.0',
        reason: 'coasting (0.0) must be serialized, not omitted',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Timestamps
  // ---------------------------------------------------------------------------

  group('timestamps', () {
    test('all Time elements end with Z (UTC)', () {
      final ride = makeRide(efforts: [effort1, effort2]);
      final xml = TcxSerializer.serialize(ride, readings);
      final doc = XmlDocument.parse(xml);

      final times =
          doc.findAllElements('Time').map((e) => e.innerText).toList();
      expect(times, isNotEmpty);
      for (final t in times) {
        expect(t, endsWith('Z'), reason: 'timestamp "$t" must end with Z');
      }
    });

    test('Lap StartTime attributes are UTC with Z', () {
      final ride = makeRide(efforts: [effort1]);
      final xml = TcxSerializer.serialize(ride, readings.sublist(0, 3));
      final doc = XmlDocument.parse(xml);

      final lapStartTimes = doc
          .findAllElements('Lap')
          .map((l) => l.getAttribute('StartTime') ?? '')
          .toList();
      for (final t in lapStartTimes) {
        expect(t, endsWith('Z'));
      }
    });

    test('trackpoint Time matches ride startTime + offset', () {
      final ride = makeRide(efforts: []);
      final xml = TcxSerializer.serialize(
        ride,
        [const SensorReading(timestamp: Duration(seconds: 5), power: 1000)],
      );
      final doc = XmlDocument.parse(xml);

      final timeText = doc.findAllElements('Time').first.innerText;
      // ride starts at 2026-02-28T08:41:00Z + 5s = 08:41:05Z
      expect(timeText, '2026-02-28T08:41:05Z');
    });
  });

  // ---------------------------------------------------------------------------
  // XML structure
  // ---------------------------------------------------------------------------

  group('XML structure', () {
    test('document has required root elements', () {
      final ride = makeRide(efforts: []);
      final xml = TcxSerializer.serialize(ride, readings);
      final doc = XmlDocument.parse(xml);

      expect(doc.findAllElements('TrainingCenterDatabase'), isNotEmpty);
      expect(doc.findAllElements('Activities'), isNotEmpty);
      expect(doc.findAllElements('Activity'), isNotEmpty);
      expect(doc.findAllElements('Id'), isNotEmpty);
    });

    test('Activity Sport attribute is Biking', () {
      final ride = makeRide(efforts: []);
      final xml = TcxSerializer.serialize(ride, []);
      final doc = XmlDocument.parse(xml);

      final activity = doc.findAllElements('Activity').first;
      expect(activity.getAttribute('Sport'), 'Biking');
    });

    test('Id element matches ride startTime in UTC', () {
      final ride = makeRide(efforts: []);
      final xml = TcxSerializer.serialize(ride, []);
      final doc = XmlDocument.parse(xml);

      final idText = doc.findAllElements('Id').first.innerText;
      expect(idText, '2026-02-28T08:41:00Z');
    });

    test('TriggerMethod is Manual for all laps', () {
      final ride = makeRide(efforts: [effort1]);
      final xml = TcxSerializer.serialize(ride, readings);
      final doc = XmlDocument.parse(xml);

      final triggers =
          doc.findAllElements('TriggerMethod').map((e) => e.innerText).toList();
      expect(triggers, everyElement('Manual'));
    });
  });
}
