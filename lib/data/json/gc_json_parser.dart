import 'dart:convert';

import 'package:wattalizer/domain/models/sensor_reading.dart';

class GcJsonParseResult {
  const GcJsonParseResult({
    required this.startTime,
    required this.readings,
  });

  final DateTime startTime;
  final List<SensorReading> readings;
}

/// Parses a GoldenCheetah internal JSON ride file.
///
/// Format spec derived from GoldenCheetah's JsonRideFile.l / .y grammar.
/// Top-level structure:
///   { "RIDE": { "STARTTIME": "...", "RECINTSECS": 1, "SAMPLES": [...] } }
///
/// STARTTIME format: "yyyy/MM/dd hh:mm:ss UTC" (always UTC).
/// SECS: elapsed seconds from ride start (may be fractional).
///
/// Null semantics: absent field = null (dropout). WATTS: 0 = valid
/// coasting (0.0); absent = null.
class GcJsonParser {
  static GcJsonParseResult parse(String jsonContent) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonContent);
    } on FormatException {
      rethrow;
    } on Object catch (e) {
      throw FormatException('Failed to decode JSON: $e');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected JSON object at top level');
    }

    // Navigate to the ride map. GC files look like {"RIDE": {...}} where
    // the value may also be a list (multiple rides joined — take first).
    final dynamic rideRaw = decoded['RIDE'];
    final Map<String, dynamic> ride;
    if (rideRaw is Map<String, dynamic>) {
      ride = rideRaw;
    } else if (rideRaw is List && rideRaw.isNotEmpty) {
      final first = rideRaw.first;
      if (first is! Map<String, dynamic>) {
        throw const FormatException('RIDE list element is not an object');
      }
      ride = first;
    } else {
      throw const FormatException('Missing or empty "RIDE" key');
    }

    final dynamic startTimeRaw = ride['STARTTIME'];
    if (startTimeRaw is! String) {
      throw const FormatException('Missing or invalid "STARTTIME"');
    }
    final startTime = _parseStartTime(startTimeRaw);

    final dynamic samplesRaw = ride['SAMPLES'];
    if (samplesRaw == null) {
      // No SAMPLES key at all — return empty readings.
      return GcJsonParseResult(startTime: startTime, readings: const []);
    }
    if (samplesRaw is! List) {
      throw const FormatException('"SAMPLES" must be a list');
    }

    final readings = <SensorReading>[];
    for (final dynamic sampleRaw in samplesRaw) {
      if (sampleRaw is! Map<String, dynamic>) continue;

      final dynamic secsRaw = sampleRaw['SECS'];
      if (secsRaw == null) continue; // sample without SECS is unusable
      final secs = (secsRaw as num).toDouble();

      readings.add(
        SensorReading(
          timestamp: Duration(milliseconds: (secs * 1000).round()),
          power: _optDouble(sampleRaw, 'WATTS'),
          heartRate: _optInt(sampleRaw, 'HR'),
          cadence: _optDouble(sampleRaw, 'CAD'),
          crankTorque: _optDouble(sampleRaw, 'NM'),
          leftRightBalance: _optDouble(sampleRaw, 'LRBALANCE'),
        ),
      );
    }

    readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return GcJsonParseResult(startTime: startTime, readings: readings);
  }

  /// Converts "yyyy/MM/dd hh:mm:ss UTC" → DateTime (UTC).
  static DateTime _parseStartTime(String raw) {
    // "2012/02/29 10:07:33 UTC" → "2012-02-29T10:07:33Z"
    final s = raw
        .trim()
        .replaceFirst(' UTC', 'Z')
        .replaceAll('/', '-')
        .replaceFirst(' ', 'T');
    try {
      return DateTime.parse(s);
    } on FormatException {
      throw FormatException('Cannot parse STARTTIME: "$raw"');
    }
  }

  static double? _optDouble(Map<String, dynamic> map, String key) {
    final v = map[key];
    if (v == null) return null;
    return (v as num).toDouble();
  }

  static int? _optInt(Map<String, dynamic> map, String key) {
    final v = map[key];
    if (v == null) return null;
    return (v as num).toInt();
  }
}
