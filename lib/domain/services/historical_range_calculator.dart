import 'package:wattalizer/domain/interfaces/ride_repository.dart';
import 'package:wattalizer/domain/models/historical_range.dart';
import 'package:wattalizer/domain/models/history_span.dart';

class HistoricalRangeCalculator {
  /// Compute best and worst envelopes with provenance from a list of
  /// effort-level MAP curves in a single pass.
  ///
  /// Performance: O(n × 90) where n = number of efforts. Single pass.
  HistoricalRange compute(
    List<MapCurveWithProvenance> effortCurves, {
    HistorySpan span = HistorySpan.allTime,
  }) {
    const kCount = 90;

    if (effortCurves.isEmpty) {
      final empty = List<DurationRecord>.generate(
        kCount,
        (i) => DurationRecord(
          durationSeconds: i + 1,
          power: 0,
          effortId: '',
          rideId: '',
          rideDate: DateTime(2000),
          effortNumber: 0,
        ),
      );
      return HistoricalRange(
        span: span,
        best: empty,
        worst: List.of(empty),
        effortCount: 0,
      );
    }

    // Initialize best/worst from the first curve.
    final first = effortCurves.first;
    final bestPower = List<double>.from(first.curve.values);
    final worstPower = List<double>.from(first.curve.values);
    final bestProv = List<MapCurveWithProvenance>.filled(kCount, first);
    final worstProv = List<MapCurveWithProvenance>.filled(kCount, first);

    // Single pass: for each duration, find max (best) and min (worst).
    for (var e = 1; e < effortCurves.length; e++) {
      final curve = effortCurves[e];
      for (var i = 0; i < kCount; i++) {
        final v = curve.curve.values[i];
        if (v > bestPower[i]) {
          bestPower[i] = v;
          bestProv[i] = curve;
        }
        if (v < worstPower[i]) {
          worstPower[i] = v;
          worstProv[i] = curve;
        }
      }
    }

    // Monotonicity enforcement: sweep right-to-left on both envelopes.
    // If values[i] < values[i+1], bump values[i] to values[i+1] and
    // inherit provenance from the longer duration.
    for (var i = kCount - 2; i >= 0; i--) {
      if (bestPower[i] < bestPower[i + 1]) {
        bestPower[i] = bestPower[i + 1];
        bestProv[i] = bestProv[i + 1];
      }
      if (worstPower[i] < worstPower[i + 1]) {
        worstPower[i] = worstPower[i + 1];
        worstProv[i] = worstProv[i + 1];
      }
    }

    // Build DurationRecord lists.
    DurationRecord toRecord(
      int idx,
      double power,
      MapCurveWithProvenance prov,
    ) {
      return DurationRecord(
        durationSeconds: idx + 1,
        power: power,
        effortId: prov.effortId,
        rideId: prov.rideId,
        rideDate: prov.rideDate,
        effortNumber: prov.effortNumber,
      );
    }

    final best = List<DurationRecord>.generate(
      kCount,
      (i) => toRecord(i, bestPower[i], bestProv[i]),
    );
    final worst = List<DurationRecord>.generate(
      kCount,
      (i) => toRecord(i, worstPower[i], worstProv[i]),
    );

    return HistoricalRange(
      span: span,
      best: best,
      worst: worst,
      effortCount: effortCurves.length,
    );
  }
}
