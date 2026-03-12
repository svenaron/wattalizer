import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:wattalizer/domain/models/historical_range.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';

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
    this.onHoverX,
    this.cursorX,
    this.suppressInfoStrip = false,
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

  /// Called with the normalized x position (1–90) on hover, null on exit.
  final void Function(double? x)? onHoverX;

  /// External cursor position (1–90) driven by a sibling chart's hover.
  /// Renders a dashed vertical line when the user is not hovering this chart.
  final double? cursorX;

  /// When true, suppresses the info strip even if [lowerProvenanceRecords]
  /// is set. Use when the caller renders its own combined info strip.
  final bool suppressInfoStrip;

  @override
  State<MapCurveChart> createState() => _MapCurveChartState();
}

class _MapCurveChartState extends State<MapCurveChart> {
  int? _touchedDur;
  double? _touchedPower;

  void _handleTouch(FlTouchEvent event, LineTouchResponse? response) {
    final spot =
        response?.lineBarSpots?.where((s) => s.barIndex == 0).firstOrNull;
    final isExit = event is FlPointerExitEvent ||
        event is FlPanEndEvent ||
        event is FlLongPressEnd;

    final useInfoStrip = !widget.compact &&
        !widget.suppressInfoStrip &&
        (widget.lowerProvenanceRecords != null ||
            widget.provenanceRecords == null);
    if (useInfoStrip) {
      if (isExit || spot == null) {
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

    if (widget.onHoverX != null) {
      if (isExit || spot == null) {
        widget.onHoverX!(null);
      } else {
        widget.onHoverX!(spot.x);
      }
    }

    if (event is! FlTapUpEvent) return;
    if (widget.onProvenanceTap == null || widget.provenanceRecords == null) {
      return;
    }
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
    final showInfoStrip = !widget.compact &&
        !widget.suppressInfoStrip &&
        (widget.lowerProvenanceRecords != null ||
            widget.provenanceRecords == null);

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
          extraLinesData: !widget.compact
              ? () {
                  final x = _touchedDur?.toDouble() ?? widget.cursorX;
                  if (x == null) return null;
                  return ExtraLinesData(
                    verticalLines: [
                      VerticalLine(
                        x: x,
                        color: colorScheme.onSurface.withValues(alpha: 0.35),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ],
                  );
                }()
              : null,
          lineTouchData: widget.compact
              ? const LineTouchData(enabled: false)
              : LineTouchData(
                  getTouchedSpotIndicator: (barData, spotIndexes) =>
                      spotIndexes.map((_) => null).toList(),
                  touchTooltipData: (showInfoStrip || widget.suppressInfoStrip)
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
        duration: Duration.zero,
      ),
    );

    if (!showInfoStrip) return chart;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        chart,
        const SizedBox(height: 4),
        _InfoStrip(
          touchedDur: _touchedDur ?? widget.cursorX?.toInt(),
          touchedPower: _touchedPower ?? _lookupPowerAtX(widget.cursorX),
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

  double? _lookupPowerAtX(double? x) {
    if (x == null) return null;
    final idx = x.toInt() - 1;
    final vals = widget.curve.values;
    if (idx < 0 || idx >= vals.length) return null;
    final v = vals[idx];
    return v > 0 ? v : null;
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
    final durText = touchedDur != null ? '${touchedDur}s' : '--';
    final powText = touchedPower != null ? '${touchedPower!.round()} W' : '--';

    String? bestPow;
    String? worstPow;
    if (idx != null) {
      if (best != null && idx < best!.length) {
        bestPow = '${best![idx].power.round()} W';
      }
      if (worst != null && idx < worst!.length) {
        worstPow = '${worst![idx].power.round()} W';
      }
    }

    return DefaultTextStyle(
      style: labelStyle,
      child: Row(
        children: [
          Text('Average ', style: mutedStyle),
          Text(durText, style: brightStyle),
          Text(': ', style: mutedStyle),
          Text(powText, style: brightStyle),
          if (best != null) ...[
            Text('  |  ', style: mutedStyle),
            Text('Best ', style: mutedStyle),
            Text(bestPow ?? '--', style: brightStyle),
          ],
          if (worst != null) ...[
            Text('  |  ', style: mutedStyle),
            Text('10th best ', style: mutedStyle),
            Text(worstPow ?? '--', style: brightStyle),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers for trace charts
// ---------------------------------------------------------------------------

List<VerticalLine> _cursorLines(double? cursorX, Color color) {
  if (cursorX == null) return const [];
  return [
    VerticalLine(
      x: cursorX,
      color: color,
      strokeWidth: 1,
      dashArray: [4, 4],
    ),
  ];
}

SideTitles _traceBottomTitles(ColorScheme cs) => SideTitles(
      showTitles: true,
      reservedSize: 24,
      interval: 15,
      getTitlesWidget: (value, meta) => Text(
        '${value.toInt()}s',
        style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
      ),
    );

SideTitles _traceLeftTitles(ColorScheme cs) => SideTitles(
      showTitles: true,
      reservedSize: 40,
      getTitlesWidget: (value, meta) => Text(
        value.toInt().toString(),
        style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
      ),
    );

// ---------------------------------------------------------------------------
// Power trace chart
// ---------------------------------------------------------------------------

/// Renders instantaneous power for a single effort over a 90s window.
/// x = elapsed + 1 (x=1 at t=0, x=90 at t=89s), matching [MapCurveChart].
class PowerTraceChart extends StatelessWidget {
  const PowerTraceChart({
    required this.readings,
    this.cursorX,
    this.onHoverX,
    super.key,
  });

  final List<SensorReading> readings;

  /// Hover position (1–90) from the MAP chart. Null = no cursor.
  final double? cursorX;

  /// Called with the x position (1–90) when the user hovers this chart,
  /// null on exit. Used to drive the MAP chart cursor.
  final void Function(double? x)? onHoverX;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (readings.isEmpty) return const SizedBox.shrink();

    final base = readings.first.timestamp.inSeconds;
    final segs = _buildPowerSegments(readings, base);
    if (segs.isEmpty) return const SizedBox.shrink();

    var maxPwr = 0.0;
    for (final r in readings) {
      if ((r.power ?? 0) > maxPwr) maxPwr = r.power!;
    }
    final maxY = (maxPwr * 1.1).ceilToDouble();

    final lineBars = segs
        .map(
          (seg) => LineChartBarData(
            spots: seg,
            color: cs.primary.withValues(alpha: 0.7),
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
          ),
        )
        .toList();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 100,
        child: LineChart(
          LineChartData(
            lineBarsData: lineBars,
            extraLinesData: ExtraLinesData(
              verticalLines: _cursorLines(
                cursorX,
                cs.onSurface.withValues(alpha: 0.35),
              ),
            ),
            minX: 1,
            maxX: 90,
            minY: 0,
            maxY: maxY,
            clipData: const FlClipData.all(),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: _traceLeftTitles(cs)),
              bottomTitles: AxisTitles(sideTitles: _traceBottomTitles(cs)),
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
            ),
            lineTouchData: onHoverX == null
                ? const LineTouchData(enabled: false)
                : LineTouchData(
                    handleBuiltInTouches: false,
                    touchCallback: (event, response) {
                      final spot = response?.lineBarSpots?.firstOrNull;
                      final isExit = event is FlPointerExitEvent ||
                          event is FlPanEndEvent ||
                          event is FlLongPressEnd;
                      if (isExit || spot == null) {
                        onHoverX!(null);
                      } else {
                        onHoverX!(spot.x);
                      }
                    },
                  ),
          ),
          duration: Duration.zero,
        ),
      ),
    );
  }

  static List<List<FlSpot>> _buildPowerSegments(
    List<SensorReading> readings,
    int base,
  ) {
    final segs = <List<FlSpot>>[];
    var cur = <FlSpot>[];
    for (final r in readings) {
      final x = (r.timestamp.inSeconds - base).toDouble() + 1;
      if (r.power != null) {
        cur.add(FlSpot(x, r.power!));
      } else if (cur.isNotEmpty) {
        segs.add(cur);
        cur = [];
      }
    }
    if (cur.isNotEmpty) segs.add(cur);
    return segs;
  }
}

// ---------------------------------------------------------------------------
// Cadence trace chart
// ---------------------------------------------------------------------------

/// Renders instantaneous cadence for a single effort over a 90s window.
/// Same x-axis as [PowerTraceChart] and [MapCurveChart].
class CadenceTraceChart extends StatelessWidget {
  const CadenceTraceChart({
    required this.readings,
    this.cursorX,
    this.onHoverX,
    super.key,
  });

  final List<SensorReading> readings;

  /// Hover position (1–90) from the MAP chart. Null = no cursor.
  final double? cursorX;

  /// Called with the x position (1–90) when the user hovers this chart,
  /// null on exit. Used to drive the MAP chart cursor.
  final void Function(double? x)? onHoverX;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (readings.isEmpty) return const SizedBox.shrink();

    final base = readings.first.timestamp.inSeconds;
    final cadValues = readings.where((r) => r.cadence != null).toList();
    if (cadValues.isEmpty) return const SizedBox.shrink();

    final maxCad =
        cadValues.map((r) => r.cadence!).reduce((a, b) => a > b ? a : b);
    if (maxCad <= 0) return const SizedBox.shrink();

    final segs = _buildCadenceSegments(readings, base);
    if (segs.isEmpty) return const SizedBox.shrink();

    final lineBars = segs
        .map(
          (seg) => LineChartBarData(
            spots: seg,
            color: cs.tertiary.withValues(alpha: 0.7),
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
          ),
        )
        .toList();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 100,
        child: LineChart(
          LineChartData(
            lineBarsData: lineBars,
            extraLinesData: ExtraLinesData(
              verticalLines: _cursorLines(
                cursorX,
                cs.onSurface.withValues(alpha: 0.35),
              ),
            ),
            minX: 1,
            maxX: 90,
            minY: 0,
            maxY: (maxCad * 1.1).ceilToDouble(),
            clipData: const FlClipData.all(),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: _traceLeftTitles(cs)),
              bottomTitles: AxisTitles(sideTitles: _traceBottomTitles(cs)),
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
            ),
            lineTouchData: onHoverX == null
                ? const LineTouchData(enabled: false)
                : LineTouchData(
                    handleBuiltInTouches: false,
                    touchCallback: (event, response) {
                      final spot = response?.lineBarSpots?.firstOrNull;
                      final isExit = event is FlPointerExitEvent ||
                          event is FlPanEndEvent ||
                          event is FlLongPressEnd;
                      if (isExit || spot == null) {
                        onHoverX!(null);
                      } else {
                        onHoverX!(spot.x);
                      }
                    },
                  ),
          ),
          duration: Duration.zero,
        ),
      ),
    );
  }

  static List<List<FlSpot>> _buildCadenceSegments(
    List<SensorReading> readings,
    int base,
  ) {
    final segs = <List<FlSpot>>[];
    var cur = <FlSpot>[];
    for (final r in readings) {
      final x = (r.timestamp.inSeconds - base).toDouble() + 1;
      if (r.cadence != null) {
        cur.add(FlSpot(x, r.cadence!));
      } else if (cur.isNotEmpty) {
        segs.add(cur);
        cur = [];
      }
    }
    if (cur.isNotEmpty) segs.add(cur);
    return segs;
  }
}
