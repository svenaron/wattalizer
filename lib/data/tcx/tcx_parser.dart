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
    final startTime = _parseDateTime(idEl!.innerText.trim());

    // Detect ActivityExtension namespace prefix (e.g. "ns3", "tpx", "ax2")
    final prefix = _findActivityExtPrefix(doc.rootElement);

    // Collect all trackpoints, flatten across all laps
    final trackpoints = doc.findAllElements('Trackpoint').toList()
      ..sort((a, b) {
        final ta = _parseTrackpointTime(a);
        final tb = _parseTrackpointTime(b);
        return ta.compareTo(tb);
      });

    final readings = <SensorReading>[];
    for (final tp in trackpoints) {
      final time = _parseTrackpointTime(tp);
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
    // Bare datetime (no timezone) is assumed UTC.
    final dt = DateTime.parse(s);
    return dt.toUtc();
  }

  static DateTime _parseTrackpointTime(XmlElement tp) {
    final timeEl = tp.getElement('Time');
    return _parseDateTime(timeEl!.innerText.trim());
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
