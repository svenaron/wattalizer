import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/data/tcx/tcx_parser.dart';

// IG7.1 example XML (5 trackpoints, start=2026-02-28T08:41:00Z)
const _ig71Xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<TrainingCenterDatabase
  xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2"
  xmlns:ns3="http://www.garmin.com/xmlschemas/ActivityExtension/v2">
  <Activities>
    <Activity Sport="Biking">
      <Id>2026-02-28T08:41:00Z</Id>
      <Lap StartTime="2026-02-28T08:41:05Z">
        <TotalTimeSeconds>3</TotalTimeSeconds>
        <Intensity>Active</Intensity>
        <TriggerMethod>Manual</TriggerMethod>
        <Track>
          <Trackpoint>
            <Time>2026-02-28T08:41:05Z</Time>
            <HeartRateBpm><Value>168</Value></HeartRateBpm>
            <Cadence>115</Cadence>
            <Extensions>
              <ns3:TPX><ns3:Watts>1200</ns3:Watts></ns3:TPX>
            </Extensions>
          </Trackpoint>
          <Trackpoint>
            <Time>2026-02-28T08:41:06Z</Time>
            <HeartRateBpm><Value>172</Value></HeartRateBpm>
            <Cadence>120</Cadence>
            <Extensions>
              <ns3:TPX><ns3:Watts>1380</ns3:Watts></ns3:TPX>
            </Extensions>
          </Trackpoint>
          <Trackpoint>
            <Time>2026-02-28T08:41:07Z</Time>
            <Cadence>118</Cadence>
            <Extensions>
              <ns3:TPX><ns3:Watts>1290</ns3:Watts></ns3:TPX>
            </Extensions>
          </Trackpoint>
        </Track>
      </Lap>
      <Lap StartTime="2026-02-28T08:41:08Z">
        <TotalTimeSeconds>2</TotalTimeSeconds>
        <Intensity>Resting</Intensity>
        <TriggerMethod>Manual</TriggerMethod>
        <Track>
          <Trackpoint>
            <Time>2026-02-28T08:41:08Z</Time>
            <HeartRateBpm><Value>175</Value></HeartRateBpm>
            <Cadence>80</Cadence>
            <Extensions>
              <ns3:TPX><ns3:Watts>120</ns3:Watts></ns3:TPX>
            </Extensions>
          </Trackpoint>
          <Trackpoint>
            <Time>2026-02-28T08:41:09Z</Time>
            <HeartRateBpm><Value>173</Value></HeartRateBpm>
          </Trackpoint>
        </Track>
      </Lap>
    </Activity>
  </Activities>
</TrainingCenterDatabase>''';

// Same as _ig71Xml but with tpx: prefix instead of ns3:
const _tpxPrefixXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<TrainingCenterDatabase
  xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2"
  xmlns:tpx="http://www.garmin.com/xmlschemas/ActivityExtension/v2">
  <Activities>
    <Activity Sport="Biking">
      <Id>2026-02-28T08:41:00Z</Id>
      <Lap StartTime="2026-02-28T08:41:05Z">
        <TotalTimeSeconds>3</TotalTimeSeconds>
        <Intensity>Active</Intensity>
        <TriggerMethod>Manual</TriggerMethod>
        <Track>
          <Trackpoint>
            <Time>2026-02-28T08:41:05Z</Time>
            <HeartRateBpm><Value>168</Value></HeartRateBpm>
            <Cadence>115</Cadence>
            <Extensions>
              <tpx:TPX><tpx:Watts>1200</tpx:Watts></tpx:TPX>
            </Extensions>
          </Trackpoint>
          <Trackpoint>
            <Time>2026-02-28T08:41:06Z</Time>
            <Extensions>
              <tpx:TPX><tpx:Watts>1380</tpx:Watts></tpx:TPX>
            </Extensions>
          </Trackpoint>
        </Track>
      </Lap>
    </Activity>
  </Activities>
</TrainingCenterDatabase>''';

// XML with a <Watts>0</Watts> element to test coasting round-trip
const _coastingXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<TrainingCenterDatabase
  xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2"
  xmlns:ns3="http://www.garmin.com/xmlschemas/ActivityExtension/v2">
  <Activities>
    <Activity Sport="Biking">
      <Id>2026-02-28T08:41:00Z</Id>
      <Lap StartTime="2026-02-28T08:41:00Z">
        <TotalTimeSeconds>1</TotalTimeSeconds>
        <Intensity>Active</Intensity>
        <TriggerMethod>Manual</TriggerMethod>
        <Track>
          <Trackpoint>
            <Time>2026-02-28T08:41:00Z</Time>
            <Extensions>
              <ns3:TPX><ns3:Watts>0</ns3:Watts></ns3:TPX>
            </Extensions>
          </Trackpoint>
        </Track>
      </Lap>
    </Activity>
  </Activities>
</TrainingCenterDatabase>''';

void main() {
  group('parse IG7.1 example', () {
    late TcxParseResult result;

    setUpAll(() {
      result = TcxParser.parse(_ig71Xml);
    });

    test('startTime is 2026-02-28T08:41:00Z', () {
      expect(result.startTime, DateTime.utc(2026, 2, 28, 8, 41));
    });

    test('produces 5 readings', () {
      expect(result.readings.length, 5);
    });

    test('readings sorted by time (offsets 5,6,7,8,9)', () {
      final offsets =
          result.readings.map((r) => r.timestamp.inSeconds).toList();
      expect(offsets, [5, 6, 7, 8, 9]);
    });

    test('readings[0] has correct power, HR, cadence', () {
      final r = result.readings[0];
      expect(r.power, 1200.0);
      expect(r.heartRate, 168);
      expect(r.cadence, 115.0);
    });

    test('readings[1] has correct power', () {
      expect(result.readings[1].power, 1380.0);
    });

    test('readings[2].heartRate == null (HR dropout)', () {
      expect(
        result.readings[2].heartRate,
        isNull,
        reason: 'trackpoint at 08:41:07 has no HeartRateBpm element',
      );
    });

    test('readings[2] still has power and cadence', () {
      expect(result.readings[2].power, 1290.0);
      expect(result.readings[2].cadence, 118.0);
    });

    test('readings[3] has all fields', () {
      final r = result.readings[3];
      expect(r.power, 120.0);
      expect(r.heartRate, 175);
      expect(r.cadence, 80.0);
    });

    test('readings[4].power == null (power dropout)', () {
      expect(
        result.readings[4].power,
        isNull,
        reason: 'trackpoint at 08:41:09 has no Watts element',
      );
    });

    test('readings[4] still has heartRate', () {
      expect(result.readings[4].heartRate, 173);
    });

    test('readings[4].cadence == null (no Cadence element)', () {
      expect(result.readings[4].cadence, isNull);
    });
  });

  group('coasting power', () {
    test('<Watts>0</Watts> → power == 0.0 (not null)', () {
      final result = TcxParser.parse(_coastingXml);
      expect(result.readings.length, 1);
      expect(
        result.readings[0].power,
        0.0,
        reason: 'Watts=0 means coasting, not dropout',
      );
    });
  });

  group('dynamic namespace prefix', () {
    test('tpx: prefix is detected and Watts extracted correctly', () {
      final result = TcxParser.parse(_tpxPrefixXml);
      expect(result.readings.length, 2);
      expect(result.readings[0].power, 1200.0);
      expect(result.readings[1].power, 1380.0);
    });
  });

  group('edge cases', () {
    test('lap structure is discarded — all trackpoints flattened', () {
      // IG7.1 has 2 laps (3 + 2 trackpoints) — all 5 are returned flat
      final result = TcxParser.parse(_ig71Xml);
      expect(result.readings.length, 5);
    });

    test('startTime is returned as UTC', () {
      final result = TcxParser.parse(_ig71Xml);
      expect(result.startTime.isUtc, true);
    });
  });
}
