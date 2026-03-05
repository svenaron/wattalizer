import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/interfaces/ride_repository.dart';
import 'package:wattalizer/domain/models/history_span.dart';
import 'package:wattalizer/presentation/providers/all_tags_provider.dart';
import 'package:wattalizer/presentation/providers/ride_list_provider.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';
import 'package:wattalizer/presentation/providers/span_selection_provider.dart';
import 'package:wattalizer/presentation/providers/tag_filter_provider.dart';
import 'package:wattalizer/presentation/screens/ride_detail_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesAsync = ref.watch(rideListProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _SpanSelector(),
            const _TagFilter(),
            Expanded(
              child: ridesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (rides) => rides.isEmpty
                    ? const Center(
                        child: Text(
                          'No rides found',
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : _RideList(rides: rides),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Span selector
// ---------------------------------------------------------------------------

class _SpanSelector extends ConsumerWidget {
  const _SpanSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(spanSelectionProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<HistorySpan>(
        segments: const [
          ButtonSegment(value: HistorySpan.week, label: Text('Week')),
          ButtonSegment(value: HistorySpan.month, label: Text('Month')),
          ButtonSegment(value: HistorySpan.year, label: Text('Year')),
          ButtonSegment(value: HistorySpan.allTime, label: Text('All')),
        ],
        selected: {selected},
        onSelectionChanged: (s) =>
            ref.read(spanSelectionProvider.notifier).span = s.first,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tag filter chips
// ---------------------------------------------------------------------------

class _TagFilter extends ConsumerWidget {
  const _TagFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTagsAsync = ref.watch<AsyncValue<List<String>>>(allTagsProvider);
    final selectedTags = ref.watch(tagFilterProvider);

    return allTagsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (allTags) {
        if (allTags.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: allTags.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final tag = allTags[i];
              final isSelected = selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (_) {
                  final notifier = ref.read(tagFilterProvider.notifier);
                  if (isSelected) {
                    notifier.removeTag(tag);
                  } else {
                    notifier.addTag(tag);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Ride list
// ---------------------------------------------------------------------------

class _RideList extends ConsumerWidget {
  const _RideList({required this.rides});

  final List<RideSummaryRow> rides;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: rides.length,
      itemBuilder: (context, i) {
        final row = rides[i];
        return Dismissible(
          key: ValueKey(row.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: Colors.redAccent,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) => _confirmDelete(context),
          onDismissed: (_) async {
            final repo = ref.read(rideRepositoryProvider);
            await repo.deleteRide(row.id);
            ref.invalidate(rideListProvider);
          },
          child: _RideCard(row: row),
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete ride?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// ---------------------------------------------------------------------------
// Ride card
// ---------------------------------------------------------------------------

class _RideCard extends StatelessWidget {
  const _RideCard({required this.row});

  final RideSummaryRow row;

  @override
  Widget build(BuildContext context) {
    final s = row.summary;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => RideDetailScreen(rideId: row.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(row.startTime),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    _formatDuration(s.durationSeconds),
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${s.avgPower.round()} W avg  \u2022  '
                '${s.effortCount} efforts',
                style: const TextStyle(fontSize: 14),
              ),
              if (row.tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: row.tags
                      .map(
                        (t) => Chip(
                          label: Text(t),
                          labelStyle: const TextStyle(fontSize: 11),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day}/${d.month}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  static String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
