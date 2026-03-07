import 'package:uuid/uuid.dart';
import 'package:wattalizer/domain/events/autolap_events.dart';
import 'package:wattalizer/domain/models/autolap_config.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';
import 'package:wattalizer/domain/services/autolap_detector.dart';
import 'package:wattalizer/domain/services/map_curve_calculator.dart';
import 'package:wattalizer/domain/services/summary_calculator.dart';

class EffortManager {
  static const _uuid = Uuid();

  /// Creates an Effort from a detected start/end and the ride's readings.
  ///
  /// Steps:
  ///   1. Slice readings[startOffset..endOffset]
  ///   2. Compute EffortSummary from slice
  ///   3. Compute MapCurve (batch) from slice
  ///   4. Assign effortNumber (1-based, sequential)
  ///   5. Compute restSincePrevious from prior effort's endOffset
  Effort createEffort({
    required String rideId,
    required int effortNumber,
    required int startOffset,
    required int endOffset,
    required EffortType type,
    required List<SensorReading> rideReadings,
    Effort? previousEffort,
  }) {
    final summarySlice = rideReadings
        .where(
          (r) =>
              r.timestamp.inSeconds >= startOffset &&
              r.timestamp.inSeconds <= endOffset,
        )
        .toList();

    // MAP curve uses up to 90s from effort start to capture recovery taper
    final curveEndOffset = startOffset + 89;
    final curveSlice = rideReadings
        .where(
          (r) =>
              r.timestamp.inSeconds >= startOffset &&
              r.timestamp.inSeconds <= curveEndOffset,
        )
        .toList();

    final effortId = _uuid.v4();
    final summary = SummaryCalculator.computeEffortSummary(summarySlice);
    final mapCurve = MapCurveCalculator.computeBatch(curveSlice, effortId);

    final restSincePrevious =
        previousEffort != null ? startOffset - previousEffort.endOffset : null;

    return Effort(
      id: effortId,
      rideId: rideId,
      effortNumber: effortNumber,
      startOffset: startOffset,
      endOffset: endOffset,
      type: type,
      summary: summary.copyWith(restSincePrevious: restSincePrevious),
      mapCurve: mapCurve,
    );
  }

  /// Re-detect all efforts from raw readings with a new config.
  /// Returns the full list of new efforts (not persisted — caller decides).
  List<Effort> redetectEfforts({
    required String rideId,
    required List<SensorReading> readings,
    required AutoLapConfig config,
  }) {
    final detector = AutoLapDetector(config);
    final efforts = <Effort>[];

    int? pendingStartOffset;
    var pendingIsManual = false;

    for (final reading in readings) {
      final event = detector.processReading(reading);
      if (event is EffortStartedEvent) {
        pendingStartOffset = event.startOffset;
        pendingIsManual = event.isManual;
      } else if (event is EffortEndedEvent && !event.wasTooShort) {
        if (pendingStartOffset != null) {
          final effort = createEffort(
            rideId: rideId,
            effortNumber: efforts.length + 1,
            startOffset: pendingStartOffset,
            endOffset: event.endOffset,
            type: event.isManual || pendingIsManual
                ? EffortType.manual
                : EffortType.auto,
            rideReadings: readings,
            previousEffort: efforts.isNotEmpty ? efforts.last : null,
          );
          efforts.add(effort);
          pendingStartOffset = null;
        }
      }
    }

    // Finalize any open effort at ride end
    final finalEvent = detector.endRide(
      readings.isNotEmpty ? readings.last.timestamp.inSeconds : 0,
    );
    if (finalEvent is EffortEndedEvent &&
        !finalEvent.wasTooShort &&
        pendingStartOffset != null) {
      final effort = createEffort(
        rideId: rideId,
        effortNumber: efforts.length + 1,
        startOffset: pendingStartOffset,
        endOffset: finalEvent.endOffset,
        type: finalEvent.isManual || pendingIsManual
            ? EffortType.manual
            : EffortType.auto,
        rideReadings: readings,
        previousEffort: efforts.isNotEmpty ? efforts.last : null,
      );
      efforts.add(effort);
    }

    return efforts;
  }
}
