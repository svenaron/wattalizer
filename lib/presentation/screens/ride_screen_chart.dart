import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/historical_range.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';
import 'package:wattalizer/presentation/providers/historical_range_provider.dart';
import 'package:wattalizer/presentation/providers/ride_session_provider.dart';
import 'package:wattalizer/presentation/screens/ride_screen.dart';

// ---------------------------------------------------------------------------
// Chart mode — live MAP curve with historical band + record highlights
// ---------------------------------------------------------------------------

class RideChartMode extends StatelessWidget {
  const RideChartMode({
    required this.state,
    required this.ref,
    required this.isLandscape,
    super.key,
  });

  final RideStateActive state;
  final WidgetRef ref;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final historicalAsync = ref.watch(historicalRangeProvider);
    final histRange = historicalAsync.asData?.value;
    final liveCurve = state.liveEffortCurve;
    final completedEfforts = state.completedEfforts;
    final latest = state.readings.isNotEmpty ? state.readings.last : null;

    final chartData = _buildChartData(
      context: context,
      liveCurve: liveCurve,
      completedEfforts: completedEfforts,
      histRange: histRange,
    );

    return Scaffold(
      body: SafeArea(
        child: isLandscape
            ? Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: ChartSidePanel(
                      state: state,
                      latest: latest,
                      liveCurve: liveCurve,
                      ref: ref,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                      child: LineChart(chartData),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  RideModeSegmentedControl(ref: ref),
                  ChartHeader(latest: latest),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: LineChart(chartData),
                    ),
                  ),
                  KeyDurationStats(liveCurve: liveCurve),
                  RideControls(
                    onLap: () =>
                        ref.read(rideSessionProvider.notifier).manualLap(),
                    onStopConfirmed: () =>
                        ref.read(rideSessionProvider.notifier).endRide(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  LineChartData _buildChartData({
    required BuildContext context,
    required MapCurve? liveCurve,
    required List<Effort> completedEfforts,
    required HistoricalRange? histRange,
  }) {
    final cs = Theme.of(context).colorScheme;
    final lines = <LineChartBarData>[];
    final betweenBars = <BetweenBarsData>[];

    // Historical band — best/worst envelope
    if (histRange != null) {
      lines
        ..add(
          _envelopeLine(
            histRange.best.map((r) => r.power).toList(),
            cs.onSurface.withValues(alpha: 0),
          ),
        )
        ..add(
          _envelopeLine(
            histRange.worst.map((r) => r.power).toList(),
            cs.onSurface.withValues(alpha: 0),
          ),
        );
      betweenBars.add(
        BetweenBarsData(
          fromIndex: 0,
          toIndex: 1,
          color: Colors.green.withValues(alpha: 0.12),
        ),
      );
    }

    // Previous session efforts — faded
    for (final effort in completedEfforts) {
      lines.add(
        _curveLine(
          effort.mapCurve.values,
          cs.onSurface.withValues(alpha: 0.25),
          strokeWidth: 1.5,
        ),
      );
    }

    // Live curve — bold gradient + record-breaking dots
    if (liveCurve != null) {
      lines.add(
        _liveCurveLine(
          liveCurve: liveCurve,
          histRange: histRange,
        ),
      );
    }

    // Compute X max: highest duration with non-zero data across all curves
    var maxX = 1.0;
    for (final e in completedEfforts) {
      for (var i = e.mapCurve.values.length - 1; i >= 0; i--) {
        if (e.mapCurve.values[i] > 0) {
          if (i + 1 > maxX) maxX = (i + 1).toDouble();
          break;
        }
      }
    }
    if (liveCurve != null) {
      for (var i = liveCurve.values.length - 1; i >= 0; i--) {
        if (liveCurve.values[i] > 0) {
          if (i + 1 > maxX) maxX = (i + 1).toDouble();
          break;
        }
      }
    }
    if (histRange != null && histRange.best.length > maxX) {
      maxX = histRange.best.length.toDouble();
    }

    // Compute Y max across all data
    var maxY = 100.0;
    if (histRange != null) {
      for (final r in histRange.best) {
        if (r.power > maxY) maxY = r.power;
      }
    }
    for (final e in completedEfforts) {
      for (final v in e.mapCurve.values) {
        if (v > maxY) maxY = v;
      }
    }
    if (liveCurve != null) {
      for (final v in liveCurve.values) {
        if (v > maxY) maxY = v;
      }
    }
    maxY = (maxY * 1.1).ceilToDouble();

    return LineChartData(
      lineBarsData: lines,
      betweenBarsData: betweenBars,
      minX: 1,
      maxX: maxX,
      minY: 0,
      maxY: maxY,
      gridData: FlGridData(
        drawVerticalLine: false,
        getDrawingHorizontalLine: (v) => FlLine(
          color: cs.onSurface.withValues(alpha: 0.08),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(),
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurfaceVariant,
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
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
      ),
      lineTouchData: const LineTouchData(enabled: false),
    );
  }

  LineChartBarData _envelopeLine(List<double> values, Color color) {
    return LineChartBarData(
      spots: List.generate(
        values.length,
        (i) => FlSpot((i + 1).toDouble(), values[i]),
      ),
      isCurved: true,
      curveSmoothness: 0.2,
      color: color,
      barWidth: 0,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(),
    );
  }

  LineChartBarData _curveLine(
    List<double> values,
    Color color, {
    double strokeWidth = 2,
  }) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < values.length; i++)
          if (values[i] > 0) FlSpot((i + 1).toDouble(), values[i]),
      ],
      isCurved: true,
      curveSmoothness: 0.2,
      color: color,
      barWidth: strokeWidth,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(),
    );
  }

  LineChartBarData _liveCurveLine({
    required MapCurve liveCurve,
    required HistoricalRange? histRange,
  }) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < liveCurve.values.length; i++)
          if (liveCurve.values[i] > 0)
            FlSpot((i + 1).toDouble(), liveCurve.values[i]),
      ],
      isCurved: true,
      curveSmoothness: 0.2,
      gradient: const LinearGradient(
        // amber instead of yellow: readable on both dark and light surfaces
        colors: [Colors.red, Colors.amber, Colors.blue],
      ),
      barWidth: 3,
      dotData: FlDotData(
        show: histRange != null,
        checkToShowDot: (spot, _) {
          if (histRange == null) return false;
          final idx = spot.x.toInt() - 1;
          if (idx < 0 || idx >= histRange.best.length) return false;
          // Show glow dot where live curve exceeds historical best (PR!)
          return spot.y > histRange.best[idx].power && spot.y > 0;
        },
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 5,
          color: Colors.amber,
          strokeColor: Colors.deepOrange,
          strokeWidth: 2,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            Colors.red.withValues(alpha: 0.08),
            Colors.blue.withValues(alpha: 0.02),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chart mode sub-widgets
// ---------------------------------------------------------------------------

class ChartHeader extends StatelessWidget {
  const ChartHeader({required this.latest, super.key});

  final SensorReading? latest;

  @override
  Widget build(BuildContext context) {
    final power = latest?.power;
    final hr = latest?.heartRate;
    final cad = latest?.cadence;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          HeaderStat(
            value: power?.round().toString() ?? '---',
            label: 'W',
            large: true,
            color: cs.primary,
          ),
          HeaderStat(
            value: hr?.toString() ?? '--',
            label: 'bpm',
            color: cs.error,
          ),
          HeaderStat(
            value: cad?.round().toString() ?? '--',
            label: 'rpm',
            color: cs.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class HeaderStat extends StatelessWidget {
  const HeaderStat({
    required this.value,
    required this.label,
    required this.color,
    super.key,
    this.large = false,
  });

  final String value;
  final String label;
  final bool large;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: large ? 28 : 22,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 3),
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

class KeyDurationStats extends StatelessWidget {
  const KeyDurationStats({required this.liveCurve, super.key});

  final MapCurve? liveCurve;

  static const _durations = [1, 5, 15, 30, 60, 90];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _durations.map((d) {
          final val = liveCurve != null ? liveCurve!.values[d - 1] : 0.0;
          final label = d >= 60 ? '${d ~/ 60}m' : '${d}s';
          return Column(
            children: [
              Text(
                val > 0 ? val.round().toString() : '--',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class ChartSidePanel extends StatelessWidget {
  const ChartSidePanel({
    required this.state,
    required this.latest,
    required this.liveCurve,
    required this.ref,
    super.key,
  });

  final RideStateActive state;
  final SensorReading? latest;
  final MapCurve? liveCurve;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final power = latest?.power;
    final hr = latest?.heartRate;
    final cad = latest?.cadence;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            power?.round().toString() ?? '---',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
          ),
          Text(
            'watts',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          if (hr != null)
            Text(
              '$hr bpm',
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            ),
          if (cad != null)
            Text(
              '${cad.round()} rpm',
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            ),
          const Spacer(),
          KeyDurationStats(liveCurve: liveCurve),
          const SizedBox(height: 8),
          RideControls(
            onLap: () => ref.read(rideSessionProvider.notifier).manualLap(),
            onStopConfirmed: () =>
                ref.read(rideSessionProvider.notifier).endRide(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
