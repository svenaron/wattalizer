import 'package:flutter/material.dart';
import 'package:wattalizer/domain/models/map_curve.dart';

/// Mini power duration curve sparkline for history cards.
/// Draws the MAP curve shape (1–90s) as a compact line.
class Sparkline extends StatelessWidget {
  const Sparkline({
    required this.curve,
    this.width = 80,
    this.height = 32,
    super.key,
  });

  final MapCurve curve;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(values: curve.values, color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final nonZero = values.where((v) => v > 0).toList();
    if (nonZero.isEmpty) return;

    // MAP curve is non-increasing — first non-zero is max, last is min.
    final maxV = nonZero.first;
    final minV = nonZero.last;
    final range = maxV - minV;
    if (range <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    var first = true;
    final n = values.length;

    for (var i = 0; i < n; i++) {
      final v = values[i];
      if (v <= 0) continue;
      final x = (i / (n - 1)) * size.width;
      // Keep 7.5% padding top and bottom
      final y = size.height -
          ((v - minV) / range) * size.height * 0.85 -
          size.height * 0.075;
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.color != color;
}
