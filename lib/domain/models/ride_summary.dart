class RideSummary {
  const RideSummary({
    required this.durationSeconds,
    required this.activeDurationSeconds,
    required this.avgPower,
    required this.maxPower,
    required this.totalKilojoules,
    required this.readingCount,
    required this.effortCount,
    this.avgHeartRate,
    this.maxHeartRate,
    this.avgCadence,
    this.avgLeftRightBalance,
  });

  final int durationSeconds;
  final int activeDurationSeconds;
  final double avgPower; // active efforts only
  final double maxPower; // entire ride
  final int? avgHeartRate; // active efforts only
  final int? maxHeartRate; // entire ride
  final double? avgCadence; // active efforts only
  final double totalKilojoules; // active efforts only
  final double? avgLeftRightBalance; // active efforts only
  final int readingCount;
  final int effortCount;
}
