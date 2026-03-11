import 'package:flutter/material.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/effort_summary.dart';
import 'package:wattalizer/domain/models/historical_range.dart';
import 'package:wattalizer/presentation/widgets/map_curve_chart.dart';

/// Expandable card showing per-effort stats and MAP curve.
class EffortCard extends StatelessWidget {
  const EffortCard({
    required this.effort,
    this.historicalRange,
    this.isExpanded = false,
    this.onToggle,
    this.onDelete,
    this.expandedBodyKey,
    super.key,
  });

  final Effort effort;
  final HistoricalRange? historicalRange;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;
  final Key? expandedBodyKey;

  @override
  Widget build(BuildContext context) {
    final s = effort.summary;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggle,
        mouseCursor: SystemMouseCursors.click,
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: _collapsed(context, s),
          secondChild: _expanded(s),
        ),
      ),
    );
  }

  Widget _collapsed(BuildContext context, EffortSummary s) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Effort ${effort.effortNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_dur(s.durationSeconds)}  \u2022  '
                  '${s.avgPower.round()} W avg  \u2022  '
                  '${s.peakPower.round()} W peak',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: 40,
            child: MapCurveChart(
              curve: effort.mapCurve,
              effortDuration: effort.summary.durationSeconds,
              compact: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _expanded(EffortSummary s) {
    return Padding(
      key: expandedBodyKey,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Effort ${effort.effortNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove effort',
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: 12),
          MapCurveChart(
            curve: effort.mapCurve,
            historicalRange: historicalRange,
            provenanceRecords: historicalRange?.best,
            lowerProvenanceRecords: historicalRange?.worst,
            effortDuration: effort.summary.durationSeconds,
          ),
          const SizedBox(height: 12),
          _StatRow(label: 'Duration', value: _dur(s.durationSeconds)),
          _StatRow(label: 'Avg Power', value: '${s.avgPower.round()} W'),
          _StatRow(label: 'Peak Power', value: '${s.peakPower.round()} W'),
          if (s.avgHeartRate != null)
            _StatRow(label: 'Avg HR', value: '${s.avgHeartRate} bpm'),
          if (s.maxHeartRate != null)
            _StatRow(label: 'Max HR', value: '${s.maxHeartRate} bpm'),
          if (s.avgCadence != null)
            _StatRow(
              label: 'Avg Cadence',
              value: '${s.avgCadence!.round()} rpm',
            ),
          if (s.restSincePrevious != null)
            _StatRow(
              label: 'Rest since prev',
              value: _dur(s.restSincePrevious!),
            ),
        ],
      ),
    );
  }

  static String _dur(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
