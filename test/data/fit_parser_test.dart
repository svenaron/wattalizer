import 'package:fit_sdk/fit_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/data/fit/fit_parser.dart';

void main() {
  // FIT epoch offset: 1989-12-31T00:00:00Z = 631065600 seconds since Unix epoch
  const fitEpoch = 631065600;

  /// Builds a FIT file with the given records. Each record is a map of
  /// field number → value.
  List<int> buildFit(DateTime startTime, List<Map<int, Object>> records) {
    final baseFitTs = startTime.millisecondsSinceEpoch ~/ 1000 - fitEpoch;
    final encoder = Encode()..open();

    final fileIdMesg = Mesg.fromMesgNum(MesgNum.fileId)
      ..setFieldValue(0, 4); // type = activity
    encoder
      ..writeMesgDefinition(MesgDefinition.fromMesg(fileIdMesg))
      ..writeMesg(fileIdMesg);

    for (var i = 0; i < records.length; i++) {
      final rec = Mesg.fromMesgNum(MesgNum.record)
        ..setFieldValue(253, baseFitTs + i); // timestamp
      for (final entry in records[i].entries) {
        rec.setFieldValue(entry.key, entry.value);
      }
      encoder
        ..writeMesgDefinition(MesgDefinition.fromMesg(rec))
        ..writeMesg(rec);
    }

    return encoder.close();
  }

  group('FitParser.parse', () {
    final baseTime = DateTime.utc(2024, 6, 1, 10);

    test('valid power/HR/cadence → correct readings', () {
      final bytes = buildFit(baseTime, [
        {7: 300, 3: 150, 4: 90}, // power, heartRate, cadence
        {7: 320, 3: 155, 4: 92},
        {7: 310, 3: 153, 4: 91},
      ]);

      final result = FitParser.parse(bytes);

      expect(result.readings, hasLength(3));
      expect(result.startTime.isUtc, isTrue);

      final r0 = result.readings[0];
      expect(r0.timestamp, Duration.zero);
      expect(r0.power, 300.0);
      expect(r0.heartRate, 150);
      expect(r0.cadence, 90.0);

      final r1 = result.readings[1];
      expect(r1.timestamp, const Duration(seconds: 1));
      expect(r1.power, 320.0);

      final r2 = result.readings[2];
      expect(r2.timestamp, const Duration(seconds: 2));
      expect(r2.power, 310.0);
    });

    test('absent power field → null (dropout)', () {
      final bytes = buildFit(baseTime, [
        {3: 150}, // heartRate only, no power
        {7: 300, 3: 155},
        {3: 152},
      ]);

      final result = FitParser.parse(bytes);

      expect(result.readings[0].power, isNull);
      expect(result.readings[1].power, 300.0);
      expect(result.readings[2].power, isNull);
    });

    test('power == 0 → 0.0 (coasting, not dropout)', () {
      final bytes = buildFit(baseTime, [
        {7: 200},
        {7: 0},
        {7: 150},
      ]);

      final result = FitParser.parse(bytes);

      expect(result.readings[1].power, 0.0);
    });

    test('no record messages → empty readings list', () {
      final encoder = Encode()..open();
      final fileIdMesg = Mesg.fromMesgNum(MesgNum.fileId)..setFieldValue(0, 4);
      encoder
        ..writeMesgDefinition(MesgDefinition.fromMesg(fileIdMesg))
        ..writeMesg(fileIdMesg);
      final bytes = encoder.close();

      final result = FitParser.parse(bytes);

      expect(result.readings, isEmpty);
    });

    test('malformed bytes → throws', () {
      expect(
        () => FitParser.parse([0x00, 0x01, 0x02, 0x03]),
        throwsA(anything),
      );
    });

    test('startTime is first record timestamp in UTC', () {
      final ts = DateTime.utc(2024, 6, 15, 8, 30);
      final bytes = buildFit(ts, [
        {7: 250},
        {7: 260},
      ]);

      final result = FitParser.parse(bytes);

      expect(result.startTime.isUtc, isTrue);
      expect(result.startTime.year, 2024);
      expect(result.startTime.month, 6);
      expect(result.startTime.day, 15);
      expect(result.startTime.hour, 8);
      expect(result.startTime.minute, 30);
    });

    test('timestamps become Duration offsets from startTime', () {
      final bytes = buildFit(baseTime, [
        {7: 100},
        {7: 110},
        {7: 120},
        {7: 130},
      ]);

      final result = FitParser.parse(bytes);

      expect(result.readings[0].timestamp, Duration.zero);
      expect(result.readings[1].timestamp, const Duration(seconds: 1));
      expect(result.readings[2].timestamp, const Duration(seconds: 2));
      expect(result.readings[3].timestamp, const Duration(seconds: 3));
    });
  });
}
