import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';

/// Horizontal bar showing effort segments with an optional power trace
/// overlaid on top.
class EffortTimeline extends StatelessWidget {
  const EffortTimeline({
    required this.efforts,
    required this.totalDurationSeconds,
    this.readings,
    this.onEffortTapped,
    super.key,
  });

  final List<Effort> efforts;
  final int totalDurationSeconds;
  final List<SensorReading>? readings;
  final ValueChanged<int>? onEffortTapped;

  @override
  Widget build(BuildContext context) {
    if (totalDurationSeconds <= 0) return const SizedBox.shrink();

    return MouseRegion(
      cursor:
          onEffortTapped != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTapUp: onEffortTapped == null
            ? null
            : (details) {
                final frac = details.localPosition.dx / context.size!.width;
                final offset = (frac * totalDurationSeconds).round();
                for (final e in efforts) {
                  if (offset >= e.startOffset &&
                      offset <= e.startOffset + e.summary.durationSeconds) {
                    onEffortTapped!(e.effortNumber);
                    return;
                  }
                }
              },
        child: CustomPaint(
          painter: _TimelinePainter(
            efforts: efforts,
            totalDuration: totalDurationSeconds,
            bgColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.12),
            readings: readings,
            powerLineColor: Theme.of(context).colorScheme.onSurface,
          ),
          child: const SizedBox(height: 64, width: double.infinity),
        ),
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({
    required this.efforts,
    required this.totalDuration,
    required this.bgColor,
    required this.powerLineColor,
    this.readings,
  });

  final List<Effort> efforts;
  final int totalDuration;
  final Color bgColor;
  final Color powerLineColor;
  final List<SensorReading>? readings;

  @override
  void paint(Canvas canvas, Size size) {
    // Background bar.
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(4),
    );
    canvas.drawRRect(rrect, Paint()..color = bgColor);

    if (efforts.isEmpty || totalDuration <= 0) {
      _drawPowerTrace(canvas, size);
      return;
    }

    final maxPower = efforts.fold<double>(
      0,
      (prev, e) => e.summary.avgPower > prev ? e.summary.avgPower : prev,
    );

    for (final effort in efforts) {
      final left = effort.startOffset / totalDuration * size.width;
      final width = effort.summary.durationSeconds / totalDuration * size.width;
      final pct = maxPower > 0 ? effort.summary.avgPower / maxPower : 0.5;
      final color = _intensityColor(pct);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            left,
            0,
            width.clamp(2, size.width - left),
            size.height,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = color,
      );
    }

    _drawPowerTrace(canvas, size);
  }

  void _drawPowerTrace(Canvas canvas, Size size) {
    final rs = readings;
    if (rs == null || rs.isEmpty || totalDuration <= 0) return;

    final nonNull =
        rs.where((r) => r.power != null).map((r) => r.power!).toList();
    if (nonNull.isEmpty) return;

    final maxP = nonNull.reduce(max);
    if (maxP <= 0) return;

    // Clip trace to the bar's rounded corners.
    canvas
      ..save()
      ..clipRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(4),
        ),
      );

    final linePath = Path();
    final fillPath = Path();
    var penDown = false;
    var lastX = 0.0;

    for (final r in rs) {
      final x = r.timestamp.inSeconds / totalDuration * size.width;
      if (r.power == null) {
        if (penDown) {
          fillPath
            ..lineTo(lastX, size.height)
            ..close();
          penDown = false;
        }
        continue;
      }
      final y = size.height - (r.power! / maxP) * size.height;
      if (!penDown) {
        linePath.moveTo(x, y);
        fillPath
          ..moveTo(x, size.height)
          ..lineTo(x, y);
        penDown = true;
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
      lastX = x;
    }

    if (penDown) {
      fillPath
        ..lineTo(lastX, size.height)
        ..close();
    }

    canvas
      ..drawPath(
        fillPath,
        Paint()
          ..color = powerLineColor.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill,
      )
      ..drawPath(
        linePath,
        Paint()
          ..color = powerLineColor.withValues(alpha: 0.70)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      )
      ..restore();
  }

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

  @override
  bool shouldRepaint(_TimelinePainter old) =>
      efforts != old.efforts ||
      totalDuration != old.totalDuration ||
      bgColor != old.bgColor ||
      readings != old.readings ||
      powerLineColor != old.powerLineColor;
}
