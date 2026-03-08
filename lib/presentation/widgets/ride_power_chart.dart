import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';

const _kLeftReserved = 40.0;
const _kRightReserved = 8.0;
const _kEffortHitSlopSeconds = 5;

String _fmtTime(int secs) => '${(secs ~/ 60).toString().padLeft(2, '0')}'
    ':${(secs % 60).toString().padLeft(2, '0')}';

Color _intensityColor(double pct) {
  if (pct < 0.5) {
    return Color.lerp(
      const Color(0xFF42A5F5),
      const Color(0xFFFFA726),
      pct / 0.5,
    )!;
  }
  return Color.lerp(
    const Color(0xFFFFA726),
    const Color(0xFFEF5350),
    (pct - 0.5) / 0.5,
  )!;
}

class RidePowerChart extends StatefulWidget {
  const RidePowerChart({
    required this.readings,
    required this.efforts,
    required this.totalDurationSeconds,
    this.onEffortDoubleTapped,
    super.key,
  });

  final List<SensorReading> readings;
  final List<Effort> efforts;
  final int totalDurationSeconds;
  final ValueChanged<int>? onEffortDoubleTapped;

  @override
  State<RidePowerChart> createState() => _RidePowerChartState();
}

class _RidePowerChartState extends State<RidePowerChart> {
  int _pixelToTime(double localX, double widgetWidth) {
    final chartW = widgetWidth - _kLeftReserved - _kRightReserved;
    final relX = (localX - _kLeftReserved).clamp(0.0, chartW);
    return (relX / chartW * widget.totalDurationSeconds).round();
  }

  Effort? _findEffort(int t) {
    for (final e in widget.efforts) {
      if (t >= e.startOffset && t <= e.endOffset) return e;
    }
    Effort? nearest;
    var minDist = _kEffortHitSlopSeconds + 1;
    for (final e in widget.efforts) {
      final dist = t < e.startOffset
          ? e.startOffset - t
          : t > e.endOffset
              ? t - e.endOffset
              : 0;
      if (dist <= _kEffortHitSlopSeconds && dist < minDist) {
        minDist = dist;
        nearest = e;
      }
    }
    return nearest;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final nonNull = widget.readings
        .where((r) => r.power != null)
        .map((r) => r.power!)
        .toList();
    final maxPower = nonNull.isEmpty ? 100.0 : nonNull.reduce(max);
    final maxY = maxPower * 1.1;
    // 1.0 required: max<T> needs both args as double.
    // ignore: prefer_int_literals
    final leftInterval = max(1.0, (maxY / 4).roundToDouble());

    final maxAvgPower = widget.efforts.isEmpty
        ? 1.0
        : widget.efforts.map((e) => e.summary.avgPower).reduce(max);

    final spots = widget.readings
        .map(
          (r) => r.power == null
              ? FlSpot.nullSpot
              : FlSpot(
                  r.timestamp.inSeconds.toDouble(),
                  r.power!,
                ),
        )
        .toList();

    final chartData = LineChartData(
      minX: 0,
      maxX: widget.totalDurationSeconds.toDouble(),
      minY: 0,
      maxY: maxY,
      rangeAnnotations: RangeAnnotations(
        verticalRangeAnnotations: [
          for (final e in widget.efforts)
            VerticalRangeAnnotation(
              x1: e.startOffset.toDouble(),
              x2: e.endOffset.toDouble(),
              color: _intensityColor(
                e.summary.avgPower / maxAvgPower,
              ).withValues(alpha: 0.25),
            ),
        ],
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          barWidth: 1.5,
          color: colorScheme.primary,
          dotData: const FlDotData(show: false),
        ),
      ],
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(
            reservedSize: _kRightReserved,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: _kLeftReserved,
            interval: leftInterval,
            getTitlesWidget: (v, _) => Text(
              '${v.round()}W',
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 20,
            interval: 60,
            getTitlesWidget: (v, _) => Text(
              _fmtTime(v.round()),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) => [
            for (final s in spots)
              LineTooltipItem(
                '${_fmtTime(s.x.round())}: ${s.y.round()} W',
                const TextStyle(),
              ),
          ],
        ),
      ),
    );

    return SizedBox(
      height: 180,
      child: GestureDetector(
        onDoubleTapDown: widget.onEffortDoubleTapped == null
            ? null
            : (d) {
                final box = context.findRenderObject()! as RenderBox;
                final t = _pixelToTime(
                  d.localPosition.dx,
                  box.size.width,
                );
                final effort = _findEffort(t);
                if (effort != null) {
                  widget.onEffortDoubleTapped!(effort.effortNumber);
                }
              },
        child: LineChart(chartData),
      ),
    );
  }
}
