import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:wattalizer/domain/models/historical_range.dart';
import 'package:wattalizer/domain/models/map_curve.dart';

/// Renders a MAP curve (power vs duration 1–90s) using fl_chart.
/// Optionally overlays a historical best/worst band.
/// When [provenanceRecords] is provided, tooltips include
/// source effort and date.
class MapCurveChart extends StatelessWidget {
  const MapCurveChart({
    required this.curve,
    this.historicalRange,
    this.provenanceRecords,
    this.compact = false,
    super.key,
  });

  final MapCurve curve;
  final HistoricalRange? historicalRange;
  final List<DurationRecord>? provenanceRecords;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < curve.values.length; i++) {
      final v = curve.values[i];
      if (v > 0) spots.add(FlSpot((i + 1).toDouble(), v));
    }
    if (spots.isEmpty) {
      return SizedBox(
        height: compact ? 48 : 200,
        child: const Center(
          child: Text('No data', style: TextStyle(color: Colors.white38)),
        ),
      );
    }

    final maxY = _maxY(spots);

    final mainLine = LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.2,
      color: Colors.cyanAccent,
      barWidth: compact ? 1.5 : 2.5,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: !compact,
        color: Colors.cyanAccent.withValues(alpha: 0.1),
      ),
    );

    final lineBars = <LineChartBarData>[mainLine];
    final betweenBars = <BetweenBarsData>[];

    if (historicalRange != null && !compact) {
      final bestSpots = <FlSpot>[];
      final worstSpots = <FlSpot>[];
      for (var i = 0; i < historicalRange!.best.length; i++) {
        final d = (i + 1).toDouble();
        bestSpots.add(FlSpot(d, historicalRange!.best[i].power));
        worstSpots.add(FlSpot(d, historicalRange!.worst[i].power));
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
          color: Colors.white.withValues(alpha: 0.08),
        ),
      );
    }

    return SizedBox(
      height: compact ? 48 : 200,
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
          titlesData: compact
              ? const FlTitlesData(show: false)
              : FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white38,
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
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                ),
          lineTouchData: compact
              ? const LineTouchData(enabled: false)
              : LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((s) {
                      if (s.barIndex != 0) return null;
                      final label = _tooltipLabel(s);
                      return LineTooltipItem(
                        label,
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
      ),
    );
  }

  String _tooltipLabel(LineBarSpot s) {
    final dur = s.x.toInt();
    final power = s.y.round();
    final base = '${dur}s: $power W';
    if (provenanceRecords == null) return base;
    final idx = dur - 1;
    if (idx < 0 || idx >= provenanceRecords!.length) return base;
    final r = provenanceRecords![idx];
    final d = r.rideDate.toLocal();
    final date = '${d.day}/${d.month}/${d.year}';
    return '$base\nEffort #${r.effortNumber}, $date';
  }

  double _maxY(List<FlSpot> spots) {
    var max = 0.0;
    for (final s in spots) {
      if (s.y > max) max = s.y;
    }
    if (historicalRange != null) {
      for (final r in historicalRange!.best) {
        if (r.power > max) max = r.power;
      }
    }
    return (max * 1.1).ceilToDouble();
  }
}
