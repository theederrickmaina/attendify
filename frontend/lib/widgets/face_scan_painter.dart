import 'dart:math';
import 'package:flutter/material.dart';

/// Sci-fi face tracking overlay — corner brackets, scanning line, crosshair, data grid
class FaceScanPainter extends CustomPainter {
  final double scanLineProgress; // 0.0 → 1.0, vertical sweep position
  final Color bracketColor;
  final Color gridColor;
  final double pulseValue; // 0.0 → 1.0 for pulsing effects

  FaceScanPainter({
    required this.scanLineProgress,
    this.bracketColor = const Color(0xFF00F0FF),
    this.gridColor = const Color(0xFF00F0FF),
    this.pulseValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // ── Subtle background grid ──
    _drawGrid(canvas, size);

    // ── Face zone oval guide ──
    _drawFaceOval(canvas, cx, cy, w, h);

    // ── Corner brackets ──
    _drawCornerBrackets(canvas, size);

    // ── Scanning line ──
    _drawScanLine(canvas, size);

    // ── Center crosshair ──
    _drawCrosshair(canvas, cx, cy);

    // ── Side tick marks ──
    _drawTickMarks(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawFaceOval(Canvas canvas, double cx, double cy, double w, double h) {
    final ovalW = w * 0.45;
    final ovalH = h * 0.55;
    final ovalRect = Rect.fromCenter(center: Offset(cx, cy), width: ovalW, height: ovalH);

    // Dashed oval
    final ovalPaint = Paint()
      ..color = bracketColor.withValues(alpha: 0.12 + 0.08 * pulseValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()..addOval(ovalRect);
    _drawDashedPath(canvas, path, ovalPaint, dashLength: 8, gapLength: 6);
  }

  void _drawCornerBrackets(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bracketLen = min(w, h) * 0.12;
    final margin = min(w, h) * 0.08;
    final thickness = 2.5 + (pulseValue * 0.5);

    final paint = Paint()
      ..color = bracketColor.withValues(alpha: 0.7 + 0.3 * pulseValue)
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Glow paint
    final glowPaint = Paint()
      ..color = bracketColor.withValues(alpha: 0.15 * pulseValue)
      ..strokeWidth = thickness + 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Top-left
    _drawBracket(canvas, margin, margin, bracketLen, paint, glowPaint, topLeft: true);
    // Top-right
    _drawBracket(canvas, w - margin, margin, bracketLen, paint, glowPaint, topRight: true);
    // Bottom-left
    _drawBracket(canvas, margin, h - margin, bracketLen, paint, glowPaint, bottomLeft: true);
    // Bottom-right
    _drawBracket(canvas, w - margin, h - margin, bracketLen, paint, glowPaint, bottomRight: true);
  }

  void _drawBracket(Canvas canvas, double x, double y, double len,
      Paint paint, Paint glowPaint,
      {bool topLeft = false, bool topRight = false,
      bool bottomLeft = false, bool bottomRight = false}) {
    final path = Path();
    if (topLeft) {
      path.moveTo(x, y + len);
      path.lineTo(x, y);
      path.lineTo(x + len, y);
    } else if (topRight) {
      path.moveTo(x - len, y);
      path.lineTo(x, y);
      path.lineTo(x, y + len);
    } else if (bottomLeft) {
      path.moveTo(x, y - len);
      path.lineTo(x, y);
      path.lineTo(x + len, y);
    } else if (bottomRight) {
      path.moveTo(x - len, y);
      path.lineTo(x, y);
      path.lineTo(x, y - len);
    }
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  void _drawScanLine(Canvas canvas, Size size) {
    final y = size.height * scanLineProgress;
    final margin = size.width * 0.08;

    // Main line with gradient
    final gradient = LinearGradient(
      colors: [
        bracketColor.withValues(alpha: 0.0),
        bracketColor.withValues(alpha: 0.6),
        bracketColor.withValues(alpha: 0.6),
        bracketColor.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.2, 0.8, 1.0],
    );

    final rect = Rect.fromLTWH(margin, y - 1, size.width - margin * 2, 2);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // Glow trail above the scan line
    final trailGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        bracketColor.withValues(alpha: 0.0),
        bracketColor.withValues(alpha: 0.05),
      ],
    );
    final trailRect = Rect.fromLTWH(margin, max(0, y - 40), size.width - margin * 2, 40);
    final trailPaint = Paint()..shader = trailGradient.createShader(trailRect);
    canvas.drawRect(trailRect, trailPaint);
  }

  void _drawCrosshair(Canvas canvas, double cx, double cy) {
    final paint = Paint()
      ..color = bracketColor.withValues(alpha: 0.25)
      ..strokeWidth = 1;

    const gap = 8.0;
    const armLen = 14.0;

    // Horizontal arms
    canvas.drawLine(Offset(cx - gap - armLen, cy), Offset(cx - gap, cy), paint);
    canvas.drawLine(Offset(cx + gap, cy), Offset(cx + gap + armLen, cy), paint);
    // Vertical arms
    canvas.drawLine(Offset(cx, cy - gap - armLen), Offset(cx, cy - gap), paint);
    canvas.drawLine(Offset(cx, cy + gap), Offset(cx, cy + gap + armLen), paint);

    // Tiny center dot
    canvas.drawCircle(Offset(cx, cy), 2,
        Paint()..color = bracketColor.withValues(alpha: 0.4));
  }

  void _drawTickMarks(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bracketColor.withValues(alpha: 0.15)
      ..strokeWidth = 1;

    // Left side ticks
    for (int i = 1; i < 8; i++) {
      final y = size.height * i / 8;
      canvas.drawLine(Offset(0, y), Offset(6, y), paint);
    }
    // Right side ticks
    for (int i = 1; i < 8; i++) {
      final y = size.height * i / 8;
      canvas.drawLine(Offset(size.width - 6, y), Offset(size.width, y), paint);
    }
    // Top ticks
    for (int i = 1; i < 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, 6), paint);
    }
    // Bottom ticks
    for (int i = 1; i < 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(Offset(x, size.height - 6), Offset(x, size.height), paint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint,
      {double dashLength = 5, double gapLength = 5}) {
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = min(distance + dashLength, metric.length);
        final extractPath = metric.extractPath(distance, end);
        canvas.drawPath(extractPath, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(FaceScanPainter oldDelegate) =>
      scanLineProgress != oldDelegate.scanLineProgress ||
      pulseValue != oldDelegate.pulseValue;
}

/// Status-specific overlay (match success / no match / scanning)
class FaceStatusPainter extends CustomPainter {
  final String status; // 'scanning', 'matched', 'no_match'
  final double progress; // animation progress 0→1
  final Color color;

  FaceStatusPainter({required this.status, required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = min(size.width, size.height) * 0.3;

    if (status == 'matched') {
      // Expanding circle ring
      final ringPaint = Paint()
        ..color = color.withValues(alpha: 0.4 * (1 - progress))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(Offset(cx, cy), radius * (0.8 + progress * 0.6), ringPaint);

      // Inner solid glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.08 * (1 - progress * 0.5))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(Offset(cx, cy), radius * 0.6, glowPaint);
    } else if (status == 'scanning') {
      // Rotating arc
      final arcPaint = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
      canvas.drawArc(rect, progress * 2 * pi, pi * 0.6, false, arcPaint);
      canvas.drawArc(rect, progress * 2 * pi + pi, pi * 0.4, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(FaceStatusPainter oldDelegate) =>
      progress != oldDelegate.progress || status != oldDelegate.status;
}

/// Animated hex grid background painter
class HexGridPainter extends CustomPainter {
  final Color color;
  final double offset;

  HexGridPainter({this.color = const Color(0xFF00F0FF), this.offset = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const hexSize = 40.0;
    final hexH = hexSize * sqrt(3);

    for (double y = -hexH + offset % hexH; y < size.height + hexH; y += hexH) {
      for (double x = -hexSize; x < size.width + hexSize; x += hexSize * 3) {
        final row = ((y + hexH) / hexH).floor();
        final xOff = row.isEven ? 0.0 : hexSize * 1.5;
        _drawHex(canvas, x + xOff, y, hexSize, paint);
      }
    }
  }

  void _drawHex(Canvas canvas, double cx, double cy, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (60 * i - 30) * pi / 180;
      final px = cx + size * cos(angle);
      final py = cy + size * sin(angle);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(HexGridPainter oldDelegate) => offset != oldDelegate.offset;
}
