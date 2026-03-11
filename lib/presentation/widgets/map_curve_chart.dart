import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:wattalizer/domain/models/historical_range.dart';
import 'package:wattalizer/domain/models/map_curve.dart';

/// Renders a MAP curve (power vs duration 1–90s) using fl_chart.
/// Optionally overlays a historical best/worst band.
/// When [provenanceRecords] is provided, tooltips include
/// source effort and date.
/// When [lowerProvenanceRecords] is also provided, a fixed info strip
/// below the chart updates on hover/tap instead of a floating tooltip.
class MapCurveChart extends StatefulWidget {
  const MapCurveChart({
    required this.curve,
    this.historicalRange,
    this.provenanceRecords,
    this.lowerProvenanceRecords,
    this.effortDuration,
    this.compact = false,
    this.onProvenanceTap,
    super.key,
  });

  final MapCurve curve;
  final HistoricalRange? historicalRange;
  final List<DurationRecord>? provenanceRecords;

  /// The lower reference envelope (e.g. worst across all efforts).
  /// When provided alongside [provenanceRecords], replaces the floating
  /// tooltip with a fixed info strip below the chart.
  final List<DurationRecord>? lowerProvenanceRecords;

  /// Sprint portion duration in seconds. When provided (non-compact mode),
  /// the sprint region is shaded; the rest of the 90s curve is unshaded.
  final int? effortDuration;
  final bool compact;

  /// Called when the user taps a data point that has provenance info.
  final void Function(DurationRecord record)? onProvenanceTap;

  @override
  State<MapCurveChart> createState() => _MapCurveChartState();
}

class _MapCurveChartState extends State<MapCurveChart> {
  int? _touchedDur;
  double? _touchedPower;

  void _handleTouch(FlTouchEvent event, LineTouchResponse? response) {
    if (widget.lowerProvenanceRecords != null) {
      final spot =
          response?.lineBarSpots?.where((s) => s.barIndex == 0).firstOrNull;
      if (event is FlPointerExitEvent ||
          event is FlPanEndEvent ||
          event is FlLongPressEnd ||
          spot == null) {
        if (_touchedDur != null) setState(() => _touchedDur = null);
      } else {
        final dur = spot.x.toInt();
        if (_touchedDur != dur) {
          setState(() {
            _touchedDur = dur;
            _touchedPower = spot.y;
          });
        }
      }
    }

    if (event is! FlTapUpEvent) return;
    if (widget.onProvenanceTap == null || widget.provenanceRecords == null) {
      return;
    }
    final spot =
        response?.lineBarSpots?.where((s) => s.barIndex == 0).firstOrNull;
    if (spot == null) return;
    final idx = spot.x.toInt() - 1;
    if (idx < 0 || idx >= widget.provenanceRecords!.length) return;
    widget.onProvenanceTap!(widget.provenanceRecords![idx]);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final spots = <FlSpot>[];
    for (var i = 0; i < widget.curve.values.length; i++) {
      final v = widget.curve.values[i];
      if (v > 0) spots.add(FlSpot((i + 1).toDouble(), v));
    }
    if (spots.isEmpty) {
      return SizedBox(
        height: widget.compact ? 48 : 200,
        child: Center(
          child: Text(
            'No data',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
        ),
      );
    }

    final maxY = _maxY(spots);
    final showInfoStrip =
        !widget.compact && widget.lowerProvenanceRecords != null;

    final mainLine = LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.2,
      color: colorScheme.primary,
      barWidth: widget.compact ? 1.5 : 2.5,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: widget.compact,
        color: colorScheme.primary.withValues(alpha: 0.1),
      ),
    );

    final lineBars = <LineChartBarData>[mainLine];
    final betweenBars = <BetweenBarsData>[];

    if (widget.historicalRange != null && !widget.compact) {
      final bestSpots = <FlSpot>[];
      final worstSpots = <FlSpot>[];
      for (var i = 0; i < widget.historicalRange!.best.length; i++) {
        final d = (i + 1).toDouble();
        bestSpots.add(FlSpot(d, widget.historicalRange!.best[i].power));
        worstSpots.add(FlSpot(d, widget.historicalRange!.worst[i].power));
      }
      lineBars.addAll([
        LineChartBarData(
          spots: bestSpots,
          isCurved: true,
          curveSmoothness: 0.2,
          color: Colors.transparent,
          barWidth: 0,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: worstSpots,
          isCurved: true,
          curveSmoothness: 0.2,
          color: Colors.transparent,
          barWidth: 0,
          dotData: const FlDotData(show: false),
        ),
      ]);
      betweenBars.add(
        BetweenBarsData(
          fromIndex: 1,
          toIndex: 2,
          color: colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      );
    }

    if (widget.effortDuration != null && !widget.compact) {
      final sprintSpots =
          spots.where((s) => s.x <= widget.effortDuration!).toList();
      if (sprintSpots.isNotEmpty) {
        lineBars.add(
          LineChartBarData(
            spots: sprintSpots,
            isCurved: true,
            curveSmoothness: 0.2,
            color: Colors.transparent,
            barWidth: 0,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
        );
      }
    }

    final chart = SizedBox(
      height: widget.compact ? 48 : 200,
      child: LineChart(
        LineChartData(
          lineBarsData: lineBars,
          betweenBarsData: betweenBars,
          minX: 1,
          maxX: 90,
          minY: 0,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: widget.compact
              ? const FlTitlesData(show: false)
              : FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 15,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}s',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                ),
          lineTouchData: widget.compact
              ? const LineTouchData(enabled: false)
              : LineTouchData(
                  touchTooltipData: showInfoStrip
                      ? LineTouchTooltipData(
                          getTooltipItems: (spots) =>
                              spots.map((_) => null).toList(),
                        )
                      : LineTouchTooltipData(
                          getTooltipItems: (spots) => spots.map((s) {
                            if (s.barIndex != 0) return null;
                            final label = _tooltipLabel(s);
                            return LineTooltipItem(
                              label,
                              TextStyle(
                                color: colorScheme.onInverseSurface,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }).toList(),
                        ),
                  touchCallback: _handleTouch,
                ),
        ),
      ),
    );

    if (!showInfoStrip) return chart;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        chart,
        const SizedBox(height: 4),
        _InfoStrip(
          touchedDur: _touchedDur,
          touchedPower: _touchedPower,
          best: widget.provenanceRecords,
          worst: widget.lowerProvenanceRecords,
        ),
      ],
    );
  }

  String _tooltipLabel(LineBarSpot s) {
    final dur = s.x.toInt();
    final power = s.y.round();
    final base = '${dur}s: $power W';
    if (widget.provenanceRecords == null) return base;
    final idx = dur - 1;
    if (idx < 0 || idx >= widget.provenanceRecords!.length) return base;
    final r = widget.provenanceRecords![idx];
    final d = r.rideDate.toLocal();
    final date = '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
    final hint = widget.onProvenanceTap != null ? '\nTap to open' : '';
    return '$base\nEffort #${r.effortNumber}, $date$hint';
  }

  double _maxY(List<FlSpot> spots) {
    var max = 0.0;
    for (final s in spots) {
      if (s.y > max) max = s.y;
    }
    if (widget.historicalRange != null) {
      for (final r in widget.historicalRange!.best) {
        if (r.power > max) max = r.power;
      }
    }
    return (max * 1.1).ceilToDouble();
  }
}

// ---------------------------------------------------------------------------
// Info strip shown below the chart when lowerProvenanceRecords is set
// ---------------------------------------------------------------------------

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({
    required this.touchedDur,
    required this.touchedPower,
    required this.best,
    required this.worst,
  });

  final int? touchedDur;
  final double? touchedPower;
  final List<DurationRecord>? best;
  final List<DurationRecord>? worst;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final muted = colorScheme.onSurfaceVariant;
    final bright = colorScheme.onSurface;
    const labelStyle = TextStyle(fontSize: 11);
    final mutedStyle = TextStyle(fontSize: 11, color: muted);
    final brightStyle = TextStyle(
      fontSize: 11,
      color: bright,
      fontWeight: FontWeight.w600,
    );

    final idx = touchedDur != null ? touchedDur! - 1 : null;
    final durText = idx != null ? '${touchedDur}s' : '--';
    final powText = touchedPower != null ? '${touchedPower!.round()} W' : '--';

    String? bestPow;
    String? bestDate;
    String? worstPow;
    String? worstDate;
    if (idx != null) {
      if (best != null && idx < best!.length) {
        bestPow = '${best![idx].power.round()} W';
        bestDate = _fmt(best![idx].rideDate);
      }
      if (worst != null && idx < worst!.length) {
        worstPow = '${worst![idx].power.round()} W';
        worstDate = _fmt(worst![idx].rideDate);
      }
    }

    return DefaultTextStyle(
      style: labelStyle,
      child: Row(
        children: [
          // Duration + hovered power
          Text(durText, style: brightStyle),
          Text('  ·  ', style: mutedStyle),
          Text(powText, style: brightStyle),
          // Best
          if (best != null) ...[
            Text('  |  ', style: mutedStyle),
            Text('Best ', style: mutedStyle),
            Text(bestPow ?? '--', style: brightStyle),
            if (bestDate != null) ...[
              Text('  ', style: mutedStyle),
              Text(bestDate, style: mutedStyle),
            ],
          ],
          // Worst
          if (worst != null) ...[
            Text('  |  ', style: mutedStyle),
            Text('Low ', style: mutedStyle),
            Text(worstPow ?? '--', style: brightStyle),
            if (worstDate != null) ...[
              Text('  ', style: mutedStyle),
              Text(worstDate, style: mutedStyle),
            ],
          ],
        ],
      ),
    );
  }

  static String _fmt(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }
}
