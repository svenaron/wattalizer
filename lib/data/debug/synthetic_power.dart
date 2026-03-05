import 'dart:math' as math;

/// Generates a deterministic power curve for a synthetic ride.
///
/// Returns one value per second. Efforts get a raised-cosine ramp-up,
/// peak hold, and exponential decay. Recovery sections get baseline
/// power with small noise and ~1% null dropouts.
List<double?> generateRidePower({
  required int durationSeconds,
  required List<({int startOffset, int durationSeconds})> efforts,
  required double baselineWatts,
  required double peakWatts,
  int seed = 0,
}) {
  final rng = math.Random(seed);
  final result = List<double?>.filled(durationSeconds, null);

  // Build a set of all offsets inside any effort for fast lookup.
  final effortOffsets = <int>{};
  for (final e in efforts) {
    for (var t = e.startOffset; t < e.startOffset + e.durationSeconds; t++) {
      effortOffsets.add(t);
    }
  }

  // Fill baseline with noise.
  for (var t = 0; t < durationSeconds; t++) {
    result[t] = baselineWatts + _gaussian(rng, sigma: 12);
    if (result[t]! < 0) result[t] = 0.0;
  }

  // Overlay effort profiles.
  for (final e in efforts) {
    final rampUp = math.min(3, e.durationSeconds ~/ 4);
    final rampDown = math.min(5, e.durationSeconds ~/ 3);
    final holdEnd = e.startOffset + e.durationSeconds - rampDown;

    for (var t = e.startOffset;
        t < e.startOffset + e.durationSeconds && t < durationSeconds;
        t++) {
      final local = t - e.startOffset;
      double power;

      if (local < rampUp) {
        // Raised-cosine ramp from baseline to peak.
        final frac = (local + 1) / rampUp;
        final cosVal = 0.5 * (1 - math.cos(math.pi * frac));
        power = baselineWatts + (peakWatts - baselineWatts) * cosVal;
      } else if (t < holdEnd) {
        // Hold near peak with noise.
        power = peakWatts + _gaussian(rng, sigma: 30);
      } else {
        // Exponential decay back to baseline.
        final decayLocal = t - holdEnd;
        final decayTotal = rampDown;
        final decay = math.exp(-3.0 * decayLocal / decayTotal);
        power = baselineWatts +
            (peakWatts - baselineWatts) * decay +
            _gaussian(rng, sigma: 15);
      }

      result[t] = math.max(0, power);
    }
  }

  // Sprinkle ~1% nulls in recovery zones only.
  for (var t = 0; t < durationSeconds; t++) {
    if (!effortOffsets.contains(t) && rng.nextDouble() < 0.01) {
      result[t] = null;
    }
  }

  return result;
}

/// Box-Muller Gaussian approximation.
double _gaussian(math.Random rng, {required double sigma}) {
  final u1 = rng.nextDouble();
  final u2 = rng.nextDouble();
  final z = math.sqrt(-2 * math.log(u1 == 0 ? 1e-10 : u1)) *
      math.cos(2 * math.pi * u2);
  return z * sigma;
}
