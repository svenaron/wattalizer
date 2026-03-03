import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/interfaces/ride_repository.dart';
import 'package:wattalizer/domain/models/history_span.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';
import 'package:wattalizer/presentation/providers/span_selection_provider.dart';
import 'package:wattalizer/presentation/providers/tag_filter_provider.dart';

/// Rides filtered by the selected span and tag filter.
/// autoDispose — only alive while the History screen is open.
final FutureProvider<List<RideSummaryRow>> rideListProvider =
    FutureProvider.autoDispose<List<RideSummaryRow>>((ref) async {
  final span = ref.watch(spanSelectionProvider);
  final tags = ref.watch(tagFilterProvider);
  final repo = ref.read(rideRepositoryProvider);

  final now = DateTime.now();
  final from = switch (span) {
    HistorySpan.week => now.subtract(const Duration(days: 7)),
    HistorySpan.month => DateTime(now.year, now.month - 1, now.day),
    HistorySpan.year => DateTime(now.year - 1, now.month, now.day),
    HistorySpan.allTime => null,
  };

  return repo.getRides(
    from: from,
    to: now,
    tags: tags.isEmpty ? null : tags,
  );
});
