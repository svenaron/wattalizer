class EffortSummary {
  const EffortSummary({
    required this.durationSeconds,
    required this.avgPower,
    required this.peakPower,
    required this.totalKilojoules,
    this.avgHeartRate,
    this.maxHeartRate,
    this.avgCadence,
    this.avgLeftRightBalance,
    this.restSincePrevious,
  });

  final int durationSeconds;
  final double avgPower;
  final double peakPower; // highest single 1Hz reading
  final int? avgHeartRate;
  final int? maxHeartRate;
  final double? avgCadence;
  final double totalKilojoules;
  final double? avgLeftRightBalance;
  final int? restSincePrevious;
}
