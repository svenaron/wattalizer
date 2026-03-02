import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';
import 'package:xml/xml.dart';

class TcxSerializer {
  /// Serializes a ride and its readings to a TCX XML string.
  ///
  /// The ride's efforts must be populated (loaded eagerly).
  /// Readings are all readings for the ride, in any order.
  static String serialize(Ride ride, List<SensorReading> readings) {
    final sortedReadings = List.of(readings)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final sortedEfforts = List.of(ride.efforts)
      ..sort((a, b) => a.startOffset.compareTo(b.startOffset));

    final startTime = ride.startTime.toUtc();
    final laps = _buildLaps(sortedReadings, sortedEfforts);

    final builder = XmlBuilder()
      ..processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(
      'TrainingCenterDatabase',
      attributes: {
        'xmlns': 'http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2',
        'xmlns:ns3': 'http://www.garmin.com/xmlschemas/ActivityExtension/v2',
      },
      nest: () {
        builder.element(
          'Activities',
          nest: () {
            builder.element(
              'Activity',
              attributes: {'Sport': 'Biking'},
              nest: () {
                builder.element(
                  'Id',
                  nest: () {
                    builder.text(_formatTime(startTime));
                  },
                );
                for (final lap in laps) {
                  _buildLap(builder, lap, startTime);
                }
              },
            );
          },
        );
      },
    );

    return builder.buildDocument().toXmlString(pretty: true, indent: '  ');
  }

  static List<_Lap> _buildLaps(
    List<SensorReading> readings,
    List<Effort> efforts,
  ) {
    if (efforts.isEmpty) {
      return [_Lap(isActive: true, readings: readings, startOffset: 0)];
    }

    final laps = <_Lap>[];
    var cursor = 0;

    for (final effort in efforts) {
      // Gap before this effort → Resting
      final gapReadings = readings
          .where(
            (r) =>
                r.timestamp.inSeconds >= cursor &&
                r.timestamp.inSeconds < effort.startOffset,
          )
          .toList();
      if (gapReadings.isNotEmpty) {
        laps.add(
          _Lap(isActive: false, readings: gapReadings, startOffset: cursor),
        );
      }

      // The effort itself → Active
      final effortReadings = readings
          .where(
            (r) =>
                r.timestamp.inSeconds >= effort.startOffset &&
                r.timestamp.inSeconds < effort.endOffset,
          )
          .toList();
      if (effortReadings.isNotEmpty) {
        laps.add(
          _Lap(
            isActive: true,
            readings: effortReadings,
            startOffset: effort.startOffset,
          ),
        );
      }

      cursor = effort.endOffset;
    }

    // Trailing gap after last effort → Resting
    final trailingReadings =
        readings.where((r) => r.timestamp.inSeconds >= cursor).toList();
    if (trailingReadings.isNotEmpty) {
      laps.add(
        _Lap(
          isActive: false,
          readings: trailingReadings,
          startOffset: cursor,
        ),
      );
    }

    return laps;
  }

  static void _buildLap(XmlBuilder builder, _Lap lap, DateTime rideStartTime) {
    final lapStartTime = rideStartTime.add(Duration(seconds: lap.startOffset));

    builder.element(
      'Lap',
      attributes: {'StartTime': _formatTime(lapStartTime)},
      nest: () {
        builder
          ..element(
            'TotalTimeSeconds',
            nest: () {
              builder.text(lap.readings.length.toString());
            },
          )
          ..element(
            'Intensity',
            nest: () {
              builder.text(lap.isActive ? 'Active' : 'Resting');
            },
          )
          ..element(
            'TriggerMethod',
            nest: () {
              builder.text('Manual');
            },
          );
        if (lap.readings.isNotEmpty) {
          builder.element(
            'Track',
            nest: () {
              for (final reading in lap.readings) {
                _buildTrackpoint(builder, reading, rideStartTime);
              }
            },
          );
        }
      },
    );
  }

  static void _buildTrackpoint(
    XmlBuilder builder,
    SensorReading reading,
    DateTime rideStartTime,
  ) {
    final time = rideStartTime.add(reading.timestamp).toUtc();

    builder.element(
      'Trackpoint',
      nest: () {
        builder.element(
          'Time',
          nest: () {
            builder.text(_formatTime(time));
          },
        );

        if (reading.heartRate != null) {
          builder.element(
            'HeartRateBpm',
            nest: () {
              builder.element(
                'Value',
                nest: () {
                  builder.text(reading.heartRate.toString());
                },
              );
            },
          );
        }

        if (reading.cadence != null) {
          builder.element(
            'Cadence',
            nest: () {
              builder.text(reading.cadence!.round().toString());
            },
          );
        }

        // null power = sensor dropout → omit entirely
        // 0.0 power = coasting → emit <ns3:Watts>0.0</ns3:Watts>
        if (reading.power != null) {
          builder.element(
            'Extensions',
            nest: () {
              builder.element(
                'ns3:TPX',
                nest: () {
                  builder.element(
                    'ns3:Watts',
                    nest: () {
                      builder.text(reading.power.toString());
                    },
                  );
                },
              );
            },
          );
        }

        _buildRawData(builder, reading);
      },
    );
  }

  static void _buildRawData(XmlBuilder builder, SensorReading r) {
    final attrs = <String, String>{};

    if (r.crankTorque != null) attrs['crankTorque'] = r.crankTorque.toString();
    if (r.accumulatedTorque != null) {
      attrs['accumulatedTorque'] = r.accumulatedTorque.toString();
    }
    if (r.crankRevolutions != null) {
      attrs['crankRevolutions'] = r.crankRevolutions.toString();
    }
    if (r.lastCrankEventTime != null) {
      attrs['lastCrankEventTime'] = r.lastCrankEventTime.toString();
    }
    if (r.maxForceMagnitude != null) {
      attrs['maxForceMagnitude'] = r.maxForceMagnitude.toString();
    }
    if (r.minForceMagnitude != null) {
      attrs['minForceMagnitude'] = r.minForceMagnitude.toString();
    }
    if (r.maxTorqueMagnitude != null) {
      attrs['maxTorqueMagnitude'] = r.maxTorqueMagnitude.toString();
    }
    if (r.minTorqueMagnitude != null) {
      attrs['minTorqueMagnitude'] = r.minTorqueMagnitude.toString();
    }
    if (r.topDeadSpotAngle != null) {
      attrs['topDeadSpotAngle'] = r.topDeadSpotAngle.toString();
    }
    if (r.bottomDeadSpotAngle != null) {
      attrs['bottomDeadSpotAngle'] = r.bottomDeadSpotAngle.toString();
    }
    if (r.accumulatedEnergy != null) {
      attrs['accumulatedEnergy'] = r.accumulatedEnergy.toString();
    }
    if (r.rrIntervals != null && r.rrIntervals!.isNotEmpty) {
      attrs['rrIntervals'] = r.rrIntervals!.join(',');
    }

    if (attrs.isEmpty) return;

    attrs['xmlns:wz'] = 'http://wattalizer.app/xmlschemas/v1';
    builder.element('wz:RawData', attributes: attrs);
  }

  static String _formatTime(DateTime dt) {
    final utc = dt.toUtc();
    final iso = utc.toIso8601String();
    // Remove sub-second precision and ensure Z suffix
    return '${iso.substring(0, 19)}Z';
  }
}

class _Lap {
  // seconds from ride start

  const _Lap({
    required this.isActive,
    required this.readings,
    required this.startOffset,
  });
  final bool isActive;
  final List<SensorReading> readings;
  final int startOffset;
}
