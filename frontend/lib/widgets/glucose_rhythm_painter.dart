import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class GlucoseRhythmPainter extends CustomPainter {
  const GlucoseRhythmPainter({
    required this.records,
    required this.targetMin,
    required this.targetMax,
    required this.valueOf,
    required this.timeOf,
  });

  final List<Map<String, dynamic>> records;
  final double targetMin;
  final double targetMax;
  final double? Function(Map<String, dynamic>) valueOf;
  final String Function(Map<String, dynamic>) timeOf;

  @override
  void paint(Canvas canvas, Size size) {
    final values = records.map(valueOf).whereType<double>().toList();
    if (values.isEmpty) return;

    final chart = Rect.fromLTRB(42, 22, size.width - 18, size.height - 42);
    final minValue = math.min(values.reduce(math.min), targetMin) - 0.8;
    final maxValue = math.max(values.reduce(math.max), targetMax) + 0.8;
    final span = math.max(1.0, maxValue - minValue);

    double xFor(int index) {
      if (records.length == 1) return chart.center.dx;
      return chart.left + chart.width * index / (records.length - 1);
    }

    double yFor(double value) {
      return chart.bottom - (value - minValue) / span * chart.height;
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFE3ECE9)
      ..strokeWidth = 1;
    final targetPaint = Paint()
      ..color = const Color(0xFF0B8A7D).withValues(alpha: 0.18)
      ..strokeWidth = 1.5;

    for (var i = 0; i <= 4; i++) {
      final y = chart.top + chart.height * i / 4;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }
    canvas.drawLine(
      Offset(chart.left, yFor(targetMin)),
      Offset(chart.right, yFor(targetMin)),
      targetPaint,
    );
    canvas.drawLine(
      Offset(chart.left, yFor(targetMax)),
      Offset(chart.right, yFor(targetMax)),
      targetPaint,
    );

    final labelPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    for (final mark in [targetMin, targetMax]) {
      labelPainter.text = TextSpan(
        text: mark.toStringAsFixed(1),
        style: const TextStyle(
          color: Color(0xFF7A8D89),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(6, yFor(mark) - labelPainter.height / 2),
      );
    }

    final path = Path();
    for (var i = 0; i < records.length; i++) {
      final value = valueOf(records[i]);
      if (value == null) continue;
      final point = Offset(xFor(i), yFor(value));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(xFor(records.length - 1), chart.bottom)
      ..lineTo(xFor(0), chart.bottom)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x330B8A7D), Color(0x000B8A7D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(chart),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF0B8A7D)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i < records.length; i++) {
      final value = valueOf(records[i]);
      if (value == null) continue;
      final point = Offset(xFor(i), yFor(value));
      final color = value < targetMin
          ? const Color(0xFFE08A22)
          : value > targetMax
          ? const Color(0xFFC53A2E)
          : const Color(0xFF0B8A7D);
      canvas.drawCircle(point, 6, Paint()..color = Colors.white);
      canvas.drawCircle(point, 4, Paint()..color = color);

      if (records.length <= 7 ||
          i == 0 ||
          i == records.length - 1 ||
          i.isEven) {
        labelPainter.text = TextSpan(
          text: value.toStringAsFixed(1),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        );
        labelPainter.layout();
        labelPainter.paint(
          canvas,
          Offset(point.dx - labelPainter.width / 2, point.dy - 24),
        );
      }
    }

    final bottomIndexes = records.length <= 4
        ? List<int>.generate(records.length, (i) => i)
        : <int>{0, (records.length / 2).floor(), records.length - 1}.toList();
    for (final index in bottomIndexes) {
      labelPainter.text = TextSpan(
        text: timeOf(records[index]),
        style: const TextStyle(
          color: Color(0xFF6B7D79),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      );
      labelPainter.layout(maxWidth: 54);
      labelPainter.paint(
        canvas,
        Offset(xFor(index) - labelPainter.width / 2, chart.bottom + 12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant GlucoseRhythmPainter oldDelegate) {
    return oldDelegate.records != records ||
        oldDelegate.targetMin != targetMin ||
        oldDelegate.targetMax != targetMax;
  }
}
