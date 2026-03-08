import 'package:wattalizer/domain/interfaces/ride_repository.dart';
import 'package:wattalizer/domain/models/historical_range.dart';
import 'package:wattalizer/domain/models/history_span.dart';

class HistoricalRangeCalculator {
  /// Compute best and top-N envelopes with provenance from a list of
  /// effort-level MAP curves.
  ///
  /// [topN] controls the lower bound of the envelope: the lower bound at each
  /// duration is the Nth-best value (default 10). If fewer than [topN] efforts
  /// exist, the lower bound is the weakest available value.
  ///
  /// Performance: O(n × 90 × topN) — negligible for small topN.
  HistoricalRange compute(
    List<MapCurveWithProvenance> effortCurves, {
    HistorySpan span = HistorySpan.allTime,
    int topN = 10,
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

    // For each duration: maintain top-N (power, provenance) pairs, sorted desc.
    final topLists = List<List<(double, MapCurveWithProvenance)>>.generate(
      kCount,
      (_) => [],
    );

    for (final curve in effortCurves) {
      for (var i = 0; i < kCount; i++) {
        final v = curve.curve.values[i];
        final list = topLists[i];
        var inserted = false;
        for (var j = 0; j < list.length; j++) {
          if (v > list[j].$1) {
            list.insert(j, (v, curve));
            inserted = true;
            break;
          }
        }
        if (!inserted && list.length < topN) list.add((v, curve));
        if (list.length > topN) list.removeLast();
      }
    }

    // Best = highest value; worst = Nth-best (bottom of top-N band).
    final bestPower =
        List<double>.generate(kCount, (i) => topLists[i].first.$1);
    final worstPower =
        List<double>.generate(kCount, (i) => topLists[i].last.$1);
    final bestProv = List<MapCurveWithProvenance>.generate(
      kCount,
      (i) => topLists[i].first.$2,
    );
    final worstProv = List<MapCurveWithProvenance>.generate(
      kCount,
      (i) => topLists[i].last.$2,
    );

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
