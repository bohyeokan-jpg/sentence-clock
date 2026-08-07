import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../model/clock_shape.dart';

/// Paints the analog face — thin rim, 12 hour ticks, 12/3/6/9 numerals,
/// slim hour/minute hands and a fine second hand. The face outline is
/// either a circle or a rounded square (`shape`); everything inside it
/// keeps the same angular layout either way.
class AnalogClockPainter extends CustomPainter {
  final DateTime time;
  final Color ink;
  final Color accent;
  final Color faceFill;
  final ClockShape shape;

  /// When set (alarm enabled), a red hand points at this hour/minute so the
  /// set alarm time reads at a glance against the current time — same
  /// convention as the hour hand (combined hour+minute angle), just a
  /// fixed marker instead of something that ticks.
  final int? alarmHour;
  final int? alarmMinute;

  /// Shared across the main clock, the widget's clock, and the alarm
  /// dial's drag handle, so "red" always means "this is the alarm."
  static const alarmRed = Color(0xFFE74C3C);

  AnalogClockPainter({
    required this.time,
    required this.ink,
    required this.accent,
    required this.faceFill,
    this.shape = ClockShape.circle,
    this.alarmHour,
    this.alarmMinute,
  });

  static const _numerals = {0: '12', 3: '3', 6: '6', 9: '9'};

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final rimWidth = radius * 0.015;
    final facePaint = Paint()..color = faceFill;
    final rimPaint = Paint()
      ..color = ink.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = rimWidth;

    if (shape == ClockShape.circle) {
      canvas.drawCircle(center, radius, facePaint);
      canvas.drawCircle(center, radius - rimWidth, rimPaint);
    } else {
      final corner = Radius.circular(radius * 0.22);
      final faceRect = Rect.fromCenter(center: center, width: radius * 2, height: radius * 2);
      canvas.drawRRect(RRect.fromRectAndRadius(faceRect, corner), facePaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(faceRect.deflate(rimWidth), Radius.circular(corner.x - rimWidth)),
        rimPaint,
      );
    }

    for (var i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi;
      final isCardinal = i % 3 == 0; // 12/3/6/9 — already carry a numeral
      final dir = Offset(sin(angle), -cos(angle));
      final outer = center + dir * (radius * 0.95);
      final inner = center + dir * (radius * (isCardinal ? 0.84 : 0.88));
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = ink.withValues(alpha: isCardinal ? 0.55 : 0.3)
          ..strokeWidth = radius * (isCardinal ? 0.02 : 0.012)
          ..strokeCap = StrokeCap.round,
      );
    }

    _numerals.forEach((hourMark, label) {
      final angle = (hourMark / 12) * 2 * pi;
      final labelR = radius * 0.72;
      final pos = center + Offset(sin(angle), -cos(angle)) * labelR;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: GoogleFonts.notoSansKr(
            color: ink,
            fontSize: radius * 0.22,
            fontWeight: FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    });

    void drawHand(double angle, double lengthFraction, double widthFraction, Color color) {
      final end = center + Offset(sin(angle), -cos(angle)) * radius * lengthFraction;
      final paint = Paint()
        ..color = color
        ..strokeWidth = radius * widthFraction
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center, end, paint);
    }

    final hourAngle = ((time.hour % 12) + time.minute / 60) / 12 * 2 * pi;
    final minuteAngle = (time.minute + time.second / 60) / 60 * 2 * pi;
    final secondAngle = time.second / 60 * 2 * pi;

    if (alarmHour != null && alarmMinute != null) {
      final alarmAngle = ((alarmHour! % 12) + alarmMinute! / 60) / 12 * 2 * pi;
      drawHand(alarmAngle, 0.30, 0.018, alarmRed); // shortest of the three
    }

    drawHand(hourAngle, 0.42, 0.03, ink);
    drawHand(minuteAngle, 0.62, 0.022, ink);
    drawHand(secondAngle, 0.68, 0.01, accent);

    canvas.drawCircle(center, radius * 0.035, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant AnalogClockPainter oldDelegate) {
    return oldDelegate.time.second != time.second ||
        oldDelegate.ink != ink ||
        oldDelegate.accent != accent ||
        oldDelegate.faceFill != faceFill ||
        oldDelegate.shape != shape ||
        oldDelegate.alarmHour != alarmHour ||
        oldDelegate.alarmMinute != alarmMinute;
  }
}
