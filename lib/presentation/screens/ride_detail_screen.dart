import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wattalizer/domain/models/historical_range.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/domain/models/ride_summary.dart';
import 'package:wattalizer/domain/services/export_service.dart';
import 'package:wattalizer/presentation/providers/all_tags_provider.dart';
import 'package:wattalizer/presentation/providers/historical_range_provider.dart';
import 'package:wattalizer/presentation/providers/ride_detail_provider.dart';
import 'package:wattalizer/presentation/providers/ride_list_provider.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';
import 'package:wattalizer/presentation/widgets/effort_card.dart';
import 'package:wattalizer/presentation/widgets/effort_timeline.dart';
import 'package:wattalizer/presentation/widgets/tag_input.dart';

class RideDetailScreen extends ConsumerWidget {
  const RideDetailScreen({required this.rideId, super.key});

  final String rideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideAsync = ref.watch(rideDetailProvider(rideId));
    final rangeAsync = ref.watch(historicalRangeProvider);

    return rideAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (ride) {
        if (ride == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Ride not found')),
          );
        }
        final range = rangeAsync.asData?.value;
        return _DetailView(ride: ride, historicalRange: range, ref: ref);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Detail view
// ---------------------------------------------------------------------------

class _DetailView extends StatefulWidget {
  const _DetailView({
    required this.ride,
    required this.historicalRange,
    required this.ref,
  });

  final Ride ride;
  final HistoricalRange? historicalRange;
  final WidgetRef ref;

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  int? _expandedEffort;

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final s = ride.summary;

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDate(ride.startTime)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (action) => _onAction(action, ride),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'export', child: Text('Export TCX')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tags
            _TagSection(ride: ride, ref: widget.ref),
            const SizedBox(height: 16),

            // Summary stats
            _SummaryGrid(s: s),
            const SizedBox(height: 16),

            // Effort timeline
            if (ride.efforts.isNotEmpty) ...[
              Text('Efforts', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              EffortTimeline(
                efforts: ride.efforts,
                totalDurationSeconds: s.durationSeconds,
                onEffortTapped: (n) => setState(
                  () => _expandedEffort = n == _expandedEffort ? null : n,
                ),
              ),
              const SizedBox(height: 12),

              // Effort cards
              ...ride.efforts.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: EffortCard(
                    effort: e,
                    historicalRange: widget.historicalRange,
                    isExpanded: _expandedEffort == e.effortNumber,
                    onToggle: () => setState(() {
                      _expandedEffort = _expandedEffort == e.effortNumber
                          ? null
                          : e.effortNumber;
                    }),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _onAction(String action, Ride ride) async {
    switch (action) {
      case 'export':
        await _exportRide(ride);
      case 'delete':
        await _deleteRide(ride);
    }
  }

  Future<void> _exportRide(Ride ride) async {
    try {
      final repo = widget.ref.read(rideRepositoryProvider);
      final readings = await repo.getReadings(ride.id);
      final service = ExportService(repository: repo);
      final path = await service.exportTcx(ride, readings);
      if (!mounted) return;
      await SharePlus.instance.share(ShareParams(uri: Uri.file(path)));
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _deleteRide(Ride ride) async {
    final confirmed = await showDialog<bool>(
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
    );
    if (confirmed != true || !mounted) return;
    final repo = widget.ref.read(rideRepositoryProvider);
    await repo.deleteRide(ride.id);
    widget.ref.invalidate(rideListProvider);
    if (!mounted) return;
    Navigator.pop(context);
  }

  static String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day}/${d.month}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
}

// ---------------------------------------------------------------------------
// Tag editing section
// ---------------------------------------------------------------------------

class _TagSection extends ConsumerWidget {
  const _TagSection({required this.ride, required this.ref});

  final Ride ride;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTagsAsync = ref.watch(allTagsProvider);
    final allTags = allTagsAsync.asData?.value ?? <String>[];

    return TagInput(
      currentTags: ride.tags,
      allTags: allTags,
      onTagsChanged: (newTags) async {
        final repo = ref.read(rideRepositoryProvider);
        await repo.updateRide(ride.copyWith(tags: newTags));
        ref
          ..invalidate(rideDetailProvider(ride.id))
          ..invalidate(rideListProvider)
          ..invalidate(allTagsProvider);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Summary stats grid
// ---------------------------------------------------------------------------

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.s});

  final RideSummary s;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _Stat(label: 'Duration', value: _dur(s.durationSeconds)),
        _Stat(label: 'Active', value: _dur(s.activeDurationSeconds)),
        _Stat(label: 'Avg Power', value: '${s.avgPower.round()} W'),
        _Stat(label: 'Max Power', value: '${s.maxPower.round()} W'),
        if (s.avgHeartRate != null)
          _Stat(label: 'Avg HR', value: '${s.avgHeartRate} bpm'),
        if (s.maxHeartRate != null)
          _Stat(label: 'Max HR', value: '${s.maxHeartRate} bpm'),
        if (s.avgCadence != null)
          _Stat(label: 'Cadence', value: '${s.avgCadence!.round()} rpm'),
        _Stat(
          label: 'Energy',
          value: '${s.totalKilojoules.toStringAsFixed(1)} kJ',
        ),
        _Stat(label: 'Efforts', value: '${s.effortCount}'),
      ],
    );
  }

  static String _dur(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
