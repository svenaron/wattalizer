class EffortSummary {
  const EffortSummary({
    required this.durationSeconds,
    required this.avgPower,
    required this.peakPower,
    this.avgHeartRate,
    this.maxHeartRate,
    this.avgCadence,
    this.peakCadence,
    this.avgLeftRightBalance,
    this.restSincePrevious,
  });

  final int durationSeconds;
  final double avgPower;
  final double peakPower; // highest single 1Hz reading
  final int? avgHeartRate;
  final int? maxHeartRate;
  final double? avgCadence;
  final double? peakCadence; // highest single 1Hz cadence reading
  final double? avgLeftRightBalance;
  final int? restSincePrevious;

  EffortSummary copyWith({int? restSincePrevious}) {
    return EffortSummary(
      durationSeconds: durationSeconds,
      avgPower: avgPower,
      peakPower: peakPower,
      avgHeartRate: avgHeartRate,
      maxHeartRate: maxHeartRate,
      avgCadence: avgCadence,
      peakCadence: peakCadence,
      avgLeftRightBalance: avgLeftRightBalance,
      restSincePrevious: restSincePrevious ?? this.restSincePrevious,
    );
  }
}
