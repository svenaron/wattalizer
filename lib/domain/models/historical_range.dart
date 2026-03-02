import 'package:wattalizer/domain/models/history_span.dart';

class DurationRecord {
  const DurationRecord({
    required this.durationSeconds,
    required this.power,
    required this.effortId,
    required this.rideId,
    required this.rideDate,
    required this.effortNumber,
  });

  final int durationSeconds;
  final double power;
  final String effortId;
  final String rideId;
  final DateTime rideDate;
  final int effortNumber;
}

class HistoricalRange {
  const HistoricalRange({
    required this.span,
    required this.best,
    required this.worst,
    required this.effortCount,
  });

  final HistorySpan span;
  final List<DurationRecord> best; // 90 entries, best[0] = 1s best (= PDC)
  final List<DurationRecord> worst; // 90 entries
  final int effortCount;
}
