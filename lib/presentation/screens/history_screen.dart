import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/interfaces/ride_repository.dart';
import 'package:wattalizer/presentation/providers/ride_list_provider.dart';
import 'package:wattalizer/presentation/providers/ride_pdc_provider.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';
import 'package:wattalizer/presentation/screens/ride_detail_screen.dart';
import 'package:wattalizer/presentation/widgets/span_selector.dart';
import 'package:wattalizer/presentation/widgets/sparkline.dart';
import 'package:wattalizer/presentation/widgets/tag_filter.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesAsync = ref.watch(rideListProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SpanSelector(),
            const TagFilter(),
            Expanded(
              child: ridesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (rides) => rides.isEmpty
                    ? Center(
                        child: Text(
                          'No rides found',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.38),
                          ),
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
            color: Theme.of(context).colorScheme.error,
            child: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.onError,
            ),
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

class _RideCard extends ConsumerWidget {
  const _RideCard({required this.row});

  final RideSummaryRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = row.summary;
    final pdcAsync = ref.watch(ridePdcProvider(row.id));
    final pdc = pdcAsync.asData?.value;

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
                  Row(
                    children: [
                      if (pdc != null) ...[
                        Sparkline(curve: pdc),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        _formatDuration(s.durationSeconds),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
