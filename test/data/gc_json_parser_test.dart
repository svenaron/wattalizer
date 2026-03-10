import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/data/json/gc_json_parser.dart';

// A well-formed GC JSON file with a variety of sample fields.
const _sampleJson = '''
{
  "RIDE": {
    "STARTTIME": "2012/02/29 10:07:33 UTC",
    "RECINTSECS": 1,
    "DEVICETYPE": "Joule GPS",
    "IDENTIFIER": "abc123",
    "TAGS": { "Sport": "Cycling" },
    "INTERVALS": [
      { "NAME": "Sprint 1", "START": 2.0, "STOP": 5.0 }
    ],
    "SAMPLES": [
      { "SECS": 0, "WATTS": 0, "HR": 150, "CAD": 90 },
      { "SECS": 1, "WATTS": 350, "HR": 168, "CAD": 115, "NM": 22.5,
        "LRBALANCE": 51.0 },
      { "SECS": 2, "WATTS": 1200, "HR": 172, "CAD": 120 },
      { "SECS": 3, "HR": 175, "CAD": 118 },
      { "SECS": 4 }
    ]
  }
}
''';

// Minimal valid file — no optional fields.
const _minimalJson = '''
{
  "RIDE": {
    "STARTTIME": "2026/03/10 08:00:00 UTC",
    "SAMPLES": []
  }
}
''';

// Sub-second recording interval (0.25s).
const _subSecondJson = '''
{
  "RIDE": {
    "STARTTIME": "2026/01/01 00:00:00 UTC",
    "RECINTSECS": 0.25,
    "SAMPLES": [
      { "SECS": 0 },
      { "SECS": 0.25, "WATTS": 400 },
      { "SECS": 0.5, "WATTS": 420 }
    ]
  }
}
''';

void main() {
  group('GcJsonParser.parse', () {
    test('parses startTime correctly', () {
      final result = GcJsonParser.parse(_sampleJson);
      expect(result.startTime, DateTime.utc(2012, 2, 29, 10, 7, 33));
    });

    test('returns correct reading count', () {
      final result = GcJsonParser.parse(_sampleJson);
      expect(result.readings.length, 5);
    });

    test('reads power (WATTS=0 → 0.0, not null)', () {
      final result = GcJsonParser.parse(_sampleJson);
      // SECS=0 has WATTS: 0 — valid coasting
      expect(result.readings[0].power, 0.0);
    });

    test('reads positive WATTS', () {
      final result = GcJsonParser.parse(_sampleJson);
      expect(result.readings[1].power, 350.0);
      expect(result.readings[2].power, 1200.0);
    });

    test('absent WATTS → null (dropout)', () {
      final result = GcJsonParser.parse(_sampleJson);
      // SECS=3 has no WATTS key
      expect(result.readings[3].power, isNull);
      // SECS=4 has no WATTS key
      expect(result.readings[4].power, isNull);
    });

    test('reads HR correctly', () {
      final result = GcJsonParser.parse(_sampleJson);
      expect(result.readings[0].heartRate, 150);
      expect(result.readings[1].heartRate, 168);
    });

    test('absent HR → null', () {
      final result = GcJsonParser.parse(_sampleJson);
      expect(result.readings[4].heartRate, isNull);
    });

    test('reads CAD correctly', () {
      final result = GcJsonParser.parse(_sampleJson);
      expect(result.readings[0].cadence, 90.0);
      expect(result.readings[1].cadence, 115.0);
    });

    test('reads NM as crankTorque', () {
      final result = GcJsonParser.parse(_sampleJson);
      expect(result.readings[1].crankTorque, 22.5);
      expect(result.readings[0].crankTorque, isNull);
    });

    test('reads LRBALANCE as leftRightBalance', () {
      final result = GcJsonParser.parse(_sampleJson);
      expect(result.readings[1].leftRightBalance, 51.0);
      expect(result.readings[0].leftRightBalance, isNull);
    });

    test('timestamps are correct Durations', () {
      final result = GcJsonParser.parse(_sampleJson);
      expect(result.readings[0].timestamp, Duration.zero);
      expect(result.readings[1].timestamp, const Duration(seconds: 1));
      expect(result.readings[2].timestamp, const Duration(seconds: 2));
    });

    test('readings are sorted by timestamp', () {
      // Shuffle the samples in source JSON to verify sort
      const unsorted = '''
{
  "RIDE": {
    "STARTTIME": "2026/01/01 00:00:00 UTC",
    "SAMPLES": [
      { "SECS": 3, "WATTS": 300 },
      { "SECS": 1, "WATTS": 100 },
      { "SECS": 2, "WATTS": 200 }
    ]
  }
}
''';
      final result = GcJsonParser.parse(unsorted);
      expect(result.readings.map((r) => r.power), [100.0, 200.0, 300.0]);
    });

    test('empty SAMPLES → empty readings list', () {
      final result = GcJsonParser.parse(_minimalJson);
      expect(result.readings, isEmpty);
    });

    test('INTERVALS section is ignored (no error)', () {
      // _sampleJson has INTERVALS — should parse fine
      expect(() => GcJsonParser.parse(_sampleJson), returnsNormally);
    });

    test('TAGS and DEVICETYPE are ignored (no error)', () {
      expect(() => GcJsonParser.parse(_sampleJson), returnsNormally);
    });

    test('sub-second SECS → Duration in milliseconds', () {
      final result = GcJsonParser.parse(_subSecondJson);
      expect(result.readings.length, 3);
      expect(result.readings[0].timestamp, Duration.zero);
      expect(result.readings[1].timestamp, const Duration(milliseconds: 250));
      expect(result.readings[2].timestamp, const Duration(milliseconds: 500));
    });

    test('WATTS=400 parsed for sub-second sample', () {
      final result = GcJsonParser.parse(_subSecondJson);
      expect(result.readings[1].power, 400.0);
    });

    test('missing STARTTIME throws FormatException', () {
      const json = '{"RIDE": {"SAMPLES": []}}';
      expect(
        () => GcJsonParser.parse(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('missing RIDE key throws FormatException', () {
      const json = '{"STARTTIME": "2026/01/01 00:00:00 UTC"}';
      expect(
        () => GcJsonParser.parse(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('malformed JSON throws FormatException', () {
      expect(
        () => GcJsonParser.parse('{bad json'),
        throwsA(isA<FormatException>()),
      );
    });

    test('top-level array (non-object) throws FormatException', () {
      expect(
        () => GcJsonParser.parse('[1, 2, 3]'),
        throwsA(isA<FormatException>()),
      );
    });

    test('RIDE as list — takes first element', () {
      const json = '''
{
  "RIDE": [
    {
      "STARTTIME": "2026/03/10 12:00:00 UTC",
      "SAMPLES": [{ "SECS": 0, "WATTS": 500 }]
    }
  ]
}
''';
      final result = GcJsonParser.parse(json);
      expect(result.startTime, DateTime.utc(2026, 3, 10, 12));
      expect(result.readings.length, 1);
      expect(result.readings.first.power, 500.0);
    });
  });

  group('GcJsonParser._parseStartTime (via parse)', () {
    test('leap day parses correctly', () {
      final result = GcJsonParser.parse(_sampleJson);
      expect(result.startTime.isUtc, isTrue);
      expect(result.startTime.year, 2012);
      expect(result.startTime.month, 2);
      expect(result.startTime.day, 29);
      expect(result.startTime.hour, 10);
      expect(result.startTime.minute, 7);
      expect(result.startTime.second, 33);
    });

    test('result is always UTC', () {
      final result = GcJsonParser.parse(_minimalJson);
      expect(result.startTime.isUtc, isTrue);
    });

    test('invalid STARTTIME string throws FormatException', () {
      const json = '{"RIDE": {"STARTTIME": "not-a-date", "SAMPLES": []}}';
      expect(
        () => GcJsonParser.parse(json),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
