import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/models/historical_range.dart';
import 'package:wattalizer/domain/models/history_span.dart';
import 'package:wattalizer/domain/services/historical_range_calculator.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';
import 'package:wattalizer/presentation/providers/span_selection_provider.dart';
import 'package:wattalizer/presentation/providers/tag_filter_provider.dart';

/// Computes best/worst envelopes for the selected span and tag filter.
/// autoDispose — only alive while a screen needs it.
/// Invalidated by rideSessionProvider when a new ride is saved.
// (brackets omitted: importing ride_session_provider here would be circular)
final FutureProvider<HistoricalRange?> historicalRangeProvider =
    FutureProvider.autoDispose<HistoricalRange?>((ref) async {
  final span = ref.watch(spanSelectionProvider);
  final tags = ref.watch(tagFilterProvider);
  final repo = ref.read(rideRepositoryProvider);
  final calc = HistoricalRangeCalculator();

  final now = DateTime.now();
  final from = switch (span) {
    HistorySpan.week => now.subtract(const Duration(days: 7)),
    HistorySpan.month => DateTime(now.year, now.month - 1, now.day),
    HistorySpan.year => DateTime(now.year - 1, now.month, now.day),
    HistorySpan.allTime => null,
  };

  final curves = await repo.getAllEffortCurves(
    from: from,
    to: now,
    tags: tags.isEmpty ? null : tags,
  );

  if (curves.isEmpty) return null;
  return calc.compute(curves);
});
