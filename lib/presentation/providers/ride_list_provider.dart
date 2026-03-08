import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/interfaces/ride_repository.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';
import 'package:wattalizer/presentation/providers/span_selection_provider.dart';
import 'package:wattalizer/presentation/providers/tag_filter_provider.dart';
import 'package:wattalizer/presentation/utils/period_utils.dart';

/// Rides filtered by the selected span and tag filter.
/// autoDispose — only alive while the History screen is open.
final FutureProvider<List<RideSummaryRow>> rideListProvider =
    FutureProvider.autoDispose<List<RideSummaryRow>>((ref) async {
  final selection = ref.watch(spanSelectionProvider);
  final tags = ref.watch(tagFilterProvider);
  final repo = ref.read(rideRepositoryProvider);

  final period =
      computePeriod(selection.span, selection.offset, DateTime.now());

  return repo.getRides(
    from: period.from,
    to: period.to,
    tags: tags.isEmpty ? null : tags,
  );
});
