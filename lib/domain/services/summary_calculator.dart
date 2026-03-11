import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/effort_summary.dart';
import 'package:wattalizer/domain/models/ride_summary.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';

class SummaryCalculator {
  /// Compute EffortSummary from a slice of readings within effort boundaries.
  /// All readings in the slice are treated as active (within an effort).
  static EffortSummary computeEffortSummary(List<SensorReading> readings) {
    if (readings.isEmpty) {
      return const EffortSummary(
        durationSeconds: 0,
        avgPower: 0,
        peakPower: 0,
      );
    }

    double powerSum = 0;
    var powerCount = 0;
    double peakPower = 0;
    var hrSum = 0;
    var hrCount = 0;
    var maxHr = 0;
    double cadSum = 0;
    var cadCount = 0;
    double peakCadence = 0;
    double lrSum = 0;
    var lrCount = 0;

    for (final r in readings) {
      if (r.power != null) {
        powerSum += r.power!;
        powerCount++;
        if (r.power! > peakPower) peakPower = r.power!;
      }
      if (r.heartRate != null) {
        hrSum += r.heartRate!;
        hrCount++;
        if (r.heartRate! > maxHr) maxHr = r.heartRate!;
      }
      if (r.cadence != null) {
        cadSum += r.cadence!;
        cadCount++;
        if (r.cadence! > peakCadence) peakCadence = r.cadence!;
      }
      if (r.leftRightBalance != null) {
        lrSum += r.leftRightBalance!;
        lrCount++;
      }
    }

    final duration = readings.last.timestamp.inSeconds -
        readings.first.timestamp.inSeconds +
        1;
    final avgPower = powerCount > 0 ? powerSum / powerCount : 0.0;

    return EffortSummary(
      durationSeconds: duration,
      avgPower: avgPower,
      peakPower: peakPower,
      avgHeartRate: hrCount > 0 ? (hrSum / hrCount).round() : null,
      maxHeartRate: hrCount > 0 ? maxHr : null,
      avgCadence: cadCount > 0 ? cadSum / cadCount : null,
      peakCadence: cadCount > 0 ? peakCadence : null,
      avgLeftRightBalance: lrCount > 0 ? lrSum / lrCount : null,
    );
  }

  /// Compute RideSummary from the full ride readings and the detected efforts.
  ///
  /// CRITICAL DISTINCTION:
  /// - avgPower, avgHeartRate, avgCadence, avgLeftRightBalance,
  ///   activeDurationSeconds → computed from ACTIVE EFFORT READINGS ONLY
  /// - maxPower, maxHeartRate → computed from ENTIRE RIDE (all readings)
  /// - durationSeconds, readingCount → computed from ENTIRE RIDE
  static RideSummary computeRideSummary(
    List<SensorReading> allReadings,
    List<Effort> efforts,
  ) {
    if (allReadings.isEmpty) {
      return RideSummary(
        durationSeconds: 0,
        activeDurationSeconds: 0,
        avgPower: 0,
        maxPower: 0,
        readingCount: 0,
        effortCount: efforts.length,
      );
    }

    // Entire ride: max values
    double maxPower = 0;
    var maxHr = 0;
    for (final r in allReadings) {
      if (r.power != null && r.power! > maxPower) maxPower = r.power!;
      if (r.heartRate != null && r.heartRate! > maxHr) maxHr = r.heartRate!;
    }

    // Build a set of active offsets for efficient lookup
    final activeOffsets = <int>{};
    for (final e in efforts) {
      for (var t = e.startOffset; t <= e.endOffset; t++) {
        activeOffsets.add(t);
      }
    }

    double powerSum = 0;
    var powerCount = 0;
    var hrSum = 0;
    var hrCount = 0;
    double cadSum = 0;
    var cadCount = 0;
    double lrSum = 0;
    var lrCount = 0;

    for (final r in allReadings) {
      if (!activeOffsets.contains(r.timestamp.inSeconds)) continue;

      if (r.power != null) {
        powerSum += r.power!;
        powerCount++;
      }
      if (r.heartRate != null) {
        hrSum += r.heartRate!;
        hrCount++;
      }
      if (r.cadence != null) {
        cadSum += r.cadence!;
        cadCount++;
      }
      if (r.leftRightBalance != null) {
        lrSum += r.leftRightBalance!;
        lrCount++;
      }
    }

    final totalDuration = allReadings.last.timestamp.inSeconds -
        allReadings.first.timestamp.inSeconds +
        1;
    final activeDuration = activeOffsets.length;
    final avgPower = powerCount > 0 ? powerSum / powerCount : 0.0;

    return RideSummary(
      durationSeconds: totalDuration,
      activeDurationSeconds: activeDuration,
      avgPower: avgPower,
      maxPower: maxPower,
      avgHeartRate: hrCount > 0 ? (hrSum / hrCount).round() : null,
      maxHeartRate: maxHr > 0 ? maxHr : null,
      avgCadence: cadCount > 0 ? cadSum / cadCount : null,
      avgLeftRightBalance: lrCount > 0 ? lrSum / lrCount : null,
      readingCount: allReadings.length,
      effortCount: efforts.length,
    );
  }
}
