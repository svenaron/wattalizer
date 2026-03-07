import 'package:flutter/material.dart';
import 'package:wattalizer/domain/models/effort.dart';

/// Horizontal colored bar showing effort segments over ride duration.
class EffortTimeline extends StatelessWidget {
  const EffortTimeline({
    required this.efforts,
    required this.totalDurationSeconds,
    this.onEffortTapped,
    super.key,
  });

  final List<Effort> efforts;
  final int totalDurationSeconds;
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
          ),
          child: const SizedBox(height: 40, width: double.infinity),
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
  });

  final List<Effort> efforts;
  final int totalDuration;
  final Color bgColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Background bar.
    final bgPaint = Paint()..color = bgColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4)),
      bgPaint,
    );

    if (efforts.isEmpty || totalDuration <= 0) return;

    final maxPower = efforts.fold<double>(
      0,
      (prev, e) => e.summary.avgPower > prev ? e.summary.avgPower : prev,
    );

    for (final effort in efforts) {
      final left = effort.startOffset / totalDuration * size.width;
      final width = effort.summary.durationSeconds / totalDuration * size.width;
      final pct = maxPower > 0 ? effort.summary.avgPower / maxPower : 0.5;
      final color = _intensityColor(pct);

      final paint = Paint()..color = color;
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
        paint,
      );
    }
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
  bool shouldRepaint(_TimelinePainter oldDelegate) =>
      efforts != oldDelegate.efforts ||
      totalDuration != oldDelegate.totalDuration ||
      bgColor != oldDelegate.bgColor;
}
