import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/models/historical_range.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/presentation/providers/historical_range_provider.dart';
import 'package:wattalizer/presentation/screens/ride_detail_screen.dart';
import 'package:wattalizer/presentation/widgets/map_curve_chart.dart';
import 'package:wattalizer/presentation/widgets/span_selector.dart';
import 'package:wattalizer/presentation/widgets/tag_filter.dart';

class PdcScreen extends ConsumerWidget {
  const PdcScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rangeAsync = ref.watch(historicalRangeProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SpanSelector(),
            const TagFilter(),
            Expanded(
              child: rangeAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (range) => range == null
                    ? Center(
                        child: Text(
                          'No ride data yet',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.38),
                          ),
                        ),
                      )
                    : _PdcContent(range: range),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdcContent extends StatelessWidget {
  const _PdcContent({required this.range});

  final HistoricalRange range;

  void _navigateToRecord(BuildContext context, DurationRecord record) {
    unawaited(
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => RideDetailScreen(
            rideId: record.rideId,
            scrollToEffortId: record.effortId,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final curve = _curveFromBest(range);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Expanded(
            child: MapCurveChart(
              curve: curve,
              historicalRange: range,
              provenanceRecords: range.best,
              onProvenanceTap: (r) => _navigateToRecord(context, r),
            ),
          ),
          const SizedBox(height: 12),
          _StatCards(
            best: range.best,
            onTap: (r) => _navigateToRecord(context, r),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static MapCurve _curveFromBest(HistoricalRange range) {
    return MapCurve(
      entityId: 'pdc',
      values: range.best.map((r) => r.power).toList(),
      flags: List.generate(90, (_) => const MapCurveFlags()),
      computedAt: DateTime.now().toUtc(),
    );
  }
}

const _keyDurations = [1, 5, 15, 30, 60, 90];

class _StatCards extends StatelessWidget {
  const _StatCards({required this.best, this.onTap});

  final List<DurationRecord> best;
  final void Function(DurationRecord record)? onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _keyDurations.map((d) {
        final record = best[d - 1];
        return SizedBox(
          width: 100,
          child: InkWell(
            onTap: onTap != null ? () => onTap!(record) : null,
            borderRadius: BorderRadius.circular(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                child: Column(
                  children: [
                    Text(
                      '${d}s',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${record.power.round()} W',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
