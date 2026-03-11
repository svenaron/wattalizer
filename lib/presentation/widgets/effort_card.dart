import 'package:flutter/material.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/effort_summary.dart';
import 'package:wattalizer/domain/models/historical_range.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';
import 'package:wattalizer/presentation/widgets/map_curve_chart.dart';

/// Expandable card showing per-effort stats and MAP curve.
class EffortCard extends StatefulWidget {
  const EffortCard({
    required this.effort,
    this.historicalRange,
    this.rawReadings,
    this.isExpanded = false,
    this.showPower = false,
    this.showCadence = false,
    this.onToggle,
    this.onTogglePower,
    this.onToggleCadence,
    this.onDelete,
    this.expandedBodyKey,
    super.key,
  });

  final Effort effort;
  final HistoricalRange? historicalRange;
  final List<SensorReading>? rawReadings;
  final bool isExpanded;
  final bool showPower;
  final bool showCadence;
  final VoidCallback? onToggle;
  final VoidCallback? onTogglePower;
  final VoidCallback? onToggleCadence;
  final VoidCallback? onDelete;
  final Key? expandedBodyKey;

  @override
  State<EffortCard> createState() => _EffortCardState();
}

class _EffortCardState extends State<EffortCard> {
  double? _hoveredX;

  @override
  Widget build(BuildContext context) {
    final s = widget.effort.summary;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 250),
        crossFadeState: widget.isExpanded
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        firstChild: _collapsed(context, s),
        secondChild: _expanded(s),
      ),
    );
  }

  Widget _collapsed(BuildContext context, EffortSummary s) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: widget.onToggle,
      mouseCursor: SystemMouseCursors.click,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Effort ${widget.effort.effortNumber}',
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
                curve: widget.effort.mapCurve,
                effortDuration: widget.effort.summary.durationSeconds,
                compact: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _expanded(EffortSummary s) {
    final readings = widget.rawReadings ?? [];
    final hasTrace = readings.isNotEmpty;
    final hasCadenceData = readings.any((r) => r.cadence != null);

    // Find the reading closest to the hovered position for the info strip.
    SensorReading? hoveredReading;
    final hoveredX = _hoveredX;
    if (hasTrace && hoveredX != null) {
      final base = readings.first.timestamp.inSeconds;
      final targetElapsed = hoveredX - 1;
      var bestDiff = double.infinity;
      for (final r in readings) {
        final elapsed = (r.timestamp.inSeconds - base).toDouble();
        final diff = (elapsed - targetElapsed).abs();
        if (diff < bestDiff) {
          bestDiff = diff;
          hoveredReading = r;
        }
      }
    }

    // MAP power at the hovered duration, looked up from the precomputed curve.
    double? mapPower;
    if (hoveredX != null) {
      final idx = hoveredX.toInt() - 1;
      final vals = widget.effort.mapCurve.values;
      if (idx >= 0 && idx < vals.length && vals[idx] > 0) {
        mapPower = vals[idx];
      }
    }

    return Padding(
      key: widget.expandedBodyKey,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: widget.onToggle,
            mouseCursor: SystemMouseCursors.click,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Effort ${widget.effort.effortNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove effort',
                    onPressed: widget.onDelete,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          MapCurveChart(
            curve: widget.effort.mapCurve,
            historicalRange: widget.historicalRange,
            provenanceRecords: widget.historicalRange?.best,
            lowerProvenanceRecords: widget.historicalRange?.worst,
            effortDuration: widget.effort.summary.durationSeconds,
            suppressInfoStrip: hasTrace,
            onHoverX: hasTrace ? (x) => setState(() => _hoveredX = x) : null,
            cursorX: hasTrace ? _hoveredX : null,
          ),
          if (hasTrace) ...[
            _ChartSectionHeader(
              label: 'Power',
              expanded: widget.showPower,
              onTap: widget.onTogglePower ?? () {},
            ),
            if (widget.showPower)
              PowerTraceChart(
                readings: readings,
                cursorX: _hoveredX,
                onHoverX: (x) => setState(() => _hoveredX = x),
              ),
            if (hasCadenceData) ...[
              _ChartSectionHeader(
                label: 'Cadence',
                expanded: widget.showCadence,
                onTap: widget.onToggleCadence ?? () {},
              ),
              if (widget.showCadence)
                CadenceTraceChart(
                  readings: readings,
                  cursorX: _hoveredX,
                  onHoverX: (x) => setState(() => _hoveredX = x),
                ),
            ],
            const SizedBox(height: 4),
            _CombinedInfoStrip(
              hoveredDur: _hoveredX?.toInt(),
              mapPower: mapPower,
              historicalRange: widget.historicalRange,
              hoveredReading: hoveredReading,
              showPower: widget.showPower,
              showCadence: widget.showCadence,
              hasCadenceData: hasCadenceData,
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                _StatBox(
                  label: 'Duration',
                  value: '${s.durationSeconds}s',
                ),
                _StatBox(
                  label: 'Avg Power',
                  value: '${s.avgPower.round()} W',
                ),
                _StatBox(
                  label: 'Peak Power',
                  value: '${s.peakPower.round()} W',
                ),
                if (s.avgHeartRate != null)
                  _StatBox(
                    label: 'Avg HR',
                    value: '${s.avgHeartRate} bpm',
                  ),
                if (s.maxHeartRate != null)
                  _StatBox(
                    label: 'Max HR',
                    value: '${s.maxHeartRate} bpm',
                  ),
                if (s.avgCadence != null)
                  _StatBox(
                    label: 'Avg Cadence',
                    value: '${s.avgCadence!.round()} rpm',
                  ),
                if (s.restSincePrevious != null)
                  _StatBox(
                    label: 'Rest',
                    value: _dur(s.restSincePrevious!),
                  ),
              ],
            ),
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

// ---------------------------------------------------------------------------
// Section toggle header
// ---------------------------------------------------------------------------

class _ChartSectionHeader extends StatelessWidget {
  const _ChartSectionHeader({
    required this.label,
    required this.expanded,
    required this.onTap,
  });

  final String label;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          mouseCursor: SystemMouseCursors.click,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: cs.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Combined info strip
// ---------------------------------------------------------------------------

class _CombinedInfoStrip extends StatelessWidget {
  const _CombinedInfoStrip({
    required this.hoveredDur,
    required this.mapPower,
    required this.historicalRange,
    required this.hoveredReading,
    required this.showPower,
    required this.showCadence,
    required this.hasCadenceData,
  });

  final int? hoveredDur;
  final double? mapPower;
  final HistoricalRange? historicalRange;
  final SensorReading? hoveredReading;
  final bool showPower;
  final bool showCadence;
  final bool hasCadenceData;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurfaceVariant;
    final bright = cs.onSurface;
    final mutedStyle = TextStyle(fontSize: 11, color: muted);
    final brightStyle = TextStyle(
      fontSize: 11,
      color: bright,
      fontWeight: FontWeight.w600,
    );

    final best = historicalRange?.best;
    final worst = historicalRange?.worst;
    final idx = hoveredDur != null ? hoveredDur! - 1 : null;
    final mapPowText = mapPower != null ? '${mapPower!.round()} W' : '--';

    String? bestPow;
    String? worstPow;
    if (idx != null) {
      if (best != null && idx < best.length) {
        bestPow = '${best[idx].power.round()} W';
      }
      if (worst != null && idx < worst.length) {
        worstPow = '${worst[idx].power.round()} W';
      }
    }

    final powText = hoveredReading?.power != null
        ? '${hoveredReading!.power!.round()} W'
        : '--';
    final cadText = hoveredReading?.cadence != null
        ? '${hoveredReading!.cadence!.round()} rpm'
        : '--';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // MAP line (always shown)
        Row(
          children: [
            Text('Average ', style: mutedStyle),
            Text(
              hoveredDur != null ? '${hoveredDur}s' : '--',
              style: brightStyle,
            ),
            Text(': ', style: mutedStyle),
            Text(mapPowText, style: brightStyle),
            if (best != null) ...[
              Text('  |  ', style: mutedStyle),
              Text('Best ', style: mutedStyle),
              Text(bestPow ?? '--', style: brightStyle),
            ],
            if (worst != null) ...[
              Text('  |  ', style: mutedStyle),
              Text('Worst ', style: mutedStyle),
              Text(worstPow ?? '--', style: brightStyle),
            ],
          ],
        ),
        // Power line (if power chart is visible)
        if (showPower) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Text('Power: ', style: mutedStyle),
              Text(powText, style: brightStyle),
            ],
          ),
        ],
        // Cadence line (if cadence chart is visible and data exists)
        if (showCadence && hasCadenceData) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Text('Cadence: ', style: mutedStyle),
              Text(cadText, style: brightStyle),
            ],
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stat box
// ---------------------------------------------------------------------------

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
