import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/models/historical_range.dart';
import 'package:wattalizer/domain/services/historical_range_calculator.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';
import 'package:wattalizer/presentation/providers/span_selection_provider.dart';
import 'package:wattalizer/presentation/providers/tag_filter_provider.dart';
import 'package:wattalizer/presentation/utils/period_utils.dart';

/// Computes best/worst envelopes for the selected span and tag filter.
/// autoDispose — only alive while a screen needs it.
/// Invalidated by rideSessionProvider when a new ride is saved.
// (brackets omitted: importing ride_session_provider here would be circular)
final FutureProvider<HistoricalRange?> historicalRangeProvider =
    FutureProvider.autoDispose<HistoricalRange?>((ref) async {
  final selection = ref.watch(spanSelectionProvider);
  final tags = ref.watch(tagFilterProvider);
  final repo = ref.read(rideRepositoryProvider);
  final calc = HistoricalRangeCalculator();

  final period =
      computePeriod(selection.span, selection.offset, DateTime.now());

  final curves = await repo.getAllEffortCurves(
    from: period.from,
    to: period.to,
    tags: tags.isEmpty ? null : tags,
  );

  if (curves.isEmpty) return null;
  return calc.compute(curves);
});
