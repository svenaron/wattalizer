import 'package:wattalizer/domain/models/sensor_reading.dart';
import 'package:xml/xml.dart';

class TcxParseResult {
  const TcxParseResult({required this.startTime, required this.readings});
  final DateTime startTime;
  final List<SensorReading> readings;
}

class TcxParser {
  /// Parses a TCX XML string and returns the startTime and flattened readings.
  ///
  /// All lap structure is discarded — trackpoints are flattened and sorted by
  /// time. The caller (ExportService) runs AutoLapDetector on the readings and
  /// constructs the full Ride. [wz:RawData] elements are ignored on import.
  static TcxParseResult parse(String xml) {
    final doc = XmlDocument.parse(xml);

    // Extract startTime from first <Activity><Id>
    final activity = doc.findAllElements('Activity').first;
    final idEl = activity.getElement('Id');
    if (idEl == null) {
      throw const FormatException('TCX Activity missing <Id> element');
    }
    final startTime = _parseDateTime(idEl.innerText.trim());

    // Detect ActivityExtension namespace prefix
    final prefix = _findActivityExtPrefix(doc.rootElement);

    // Collect all trackpoints, skip those without valid time
    final trackpoints = doc.findAllElements('Trackpoint').toList();
    final timed = <(DateTime, XmlElement)>[];
    for (final tp in trackpoints) {
      final time = _parseTrackpointTime(tp);
      if (time != null) timed.add((time, tp));
    }
    timed.sort((a, b) => a.$1.compareTo(b.$1));

    final readings = <SensorReading>[];
    for (final (time, tp) in timed) {
      final offsetSeconds = time.difference(startTime).inSeconds;
      readings.add(
        SensorReading(
          timestamp: Duration(seconds: offsetSeconds),
          power: _extractWatts(tp, prefix),
          heartRate: _extractHeartRate(tp),
          cadence: _extractCadence(tp),
        ),
      );
    }

    return TcxParseResult(startTime: startTime, readings: readings);
  }

  static DateTime _parseDateTime(String s) {
    // DateTime.parse handles ISO 8601 including Z suffix and offset formats.
    // Dart treats bare datetimes (no timezone) as local time. Per spec S7
    // we treat them as UTC, so re-construct as UTC if not already.
    final dt = DateTime.parse(s);
    if (dt.isUtc) return dt;
    return DateTime.utc(
      dt.year,
      dt.month,
      dt.day,
      dt.hour,
      dt.minute,
      dt.second,
      dt.millisecond,
      dt.microsecond,
    );
  }

  static DateTime? _parseTrackpointTime(XmlElement tp) {
    final timeEl = tp.getElement('Time');
    if (timeEl == null) return null;
    try {
      return _parseDateTime(timeEl.innerText.trim());
    } on FormatException {
      return null;
    }
  }

  /// Scans xmlns attributes on the root element for the ActivityExtension/v2
  /// namespace and returns its prefix (e.g. "ns3"). Returns null if not found.
  static String? _findActivityExtPrefix(XmlElement root) {
    for (final attr in root.attributes) {
      if (attr.value.contains('ActivityExtension/v2')) {
        // xmlns:ns3="..." → attr.name.prefix = 'xmlns', attr.name.local = 'ns3'
        if (attr.name.prefix == 'xmlns') {
          return attr.name.local;
        }
      }
    }
    return null;
  }

  /// Extracts the watts value from a trackpoint's Extensions/TPX block.
  ///
  /// Returns null if the element is absent (dropout).
  /// Returns 0.0 if the element is present with value "0" (coasting).
  static double? _extractWatts(XmlElement tp, String? prefix) {
    final ext = tp.getElement('Extensions');
    if (ext == null) return null;

    XmlElement? wattsEl;

    if (prefix != null) {
      // Primary path: use the detected prefix
      final tpx = ext.getElement('$prefix:TPX');
      wattsEl = tpx?.getElement('$prefix:Watts');
    }

    wattsEl ??= _findByLocalName(ext, 'Watts');

    if (wattsEl == null) return null;
    return double.tryParse(wattsEl.innerText.trim());
  }

  static int? _extractHeartRate(XmlElement tp) {
    final hrBpm = tp.getElement('HeartRateBpm');
    if (hrBpm == null) return null;
    final val = hrBpm.getElement('Value');
    if (val == null) return null;
    return int.tryParse(val.innerText.trim());
  }

  static double? _extractCadence(XmlElement tp) {
    final el = tp.getElement('Cadence');
    if (el == null) return null;
    return double.tryParse(el.innerText.trim());
  }

  /// Finds the first descendant element with the given local name, ignoring
  /// namespace prefix. Used as a fallback when the prefix is unknown.
  static XmlElement? _findByLocalName(XmlElement parent, String localName) {
    for (final node in parent.descendants) {
      if (node is XmlElement && node.name.local == localName) {
        return node;
      }
    }
    return null;
  }
}
