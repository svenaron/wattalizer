import 'dart:typed_data';

import 'package:fit_sdk/fit_sdk.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';

class FitParseResult {
  const FitParseResult({required this.startTime, required this.readings});
  final DateTime startTime;
  final List<SensorReading> readings;
}

class FitParser {
  /// Parses a FIT binary file and returns the startTime and flattened readings.
  ///
  /// FIT timestamps are converted to UTC by the SDK. The first record's
  /// timestamp becomes startTime; subsequent records become Duration offsets.
  ///
  /// Null semantics: absent field = null (dropout); field == 0 = 0.0
  /// (coasting).
  static FitParseResult parse(List<int> bytes) {
    final decoder = Decode();

    final rawRecords =
        <({DateTime timestamp, int? power, int? heartRate, int? cadence})>[];

    decoder
      ..onMesg = (mesg) {
        if (mesg.num != MesgNum.record) return;
        final rec = RecordMesg.fromMesg(mesg);
        final ts = rec.getTimestamp();
        if (ts == null) return;
        rawRecords.add(
          (
            timestamp: ts.toUtc(),
            power: rec.getPower(),
            heartRate: rec.getHeartRate(),
            cadence: rec.getCadence(),
          ),
        );
      }
      ..read(Uint8List.fromList(bytes));

    if (rawRecords.isEmpty) {
      return FitParseResult(
        startTime: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        readings: const [],
      );
    }

    rawRecords.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final startTime = rawRecords.first.timestamp;
    final readings = rawRecords.map((r) {
      final offsetSeconds = r.timestamp.difference(startTime).inSeconds;
      return SensorReading(
        timestamp: Duration(seconds: offsetSeconds),
        power: r.power?.toDouble(),
        heartRate: r.heartRate,
        cadence: r.cadence?.toDouble(),
      );
    }).toList();

    return FitParseResult(startTime: startTime, readings: readings);
  }
}
