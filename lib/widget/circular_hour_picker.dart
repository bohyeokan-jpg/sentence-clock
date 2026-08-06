import 'dart:math';
import 'package:flutter/material.dart';

/// A draggable 12-position dial for picking an hour (1-12), matching the
/// "다이얼로 설정" mode from the alarm screen mockup. Minutes and AM/PM are
/// handled separately by the caller — this widget only owns the hour ring.
class CircularHourPicker extends StatefulWidget {
  final int hour12; // 1-12
  final ValueChanged<int> onChanged;
  final Color ink;
  final Color accent;
  final Color faceFill;
  final double size;

  const CircularHourPicker({
    super.key,
    required this.hour12,
    required this.onChanged,
    required this.ink,
    required this.accent,
    required this.faceFill,
    this.size = 200,
  });

  @override
  State<CircularHourPicker> createState() => _CircularHourPickerState();
}

class _CircularHourPickerState extends State<CircularHourPicker> {
  void _handleTouch(Offset localPosition) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final vector = localPosition - center;
    var angle = atan2(vector.dx, -vector.dy);
    if (angle < 0) angle += 2 * pi;
    final rawHour = (angle / (2 * pi) * 12).round() % 12;
    final hour12 = rawHour == 0 ? 12 : rawHour;
    if (hour12 != widget.hour12) widget.onChanged(hour12);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _handleTouch(d.localPosition),
      onPanUpdate: (d) => _handleTouch(d.localPosition),
      onTapUp: (d) => _handleTouch(d.localPosition),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _DialPainter(
            hour12: widget.hour12,
            ink: widget.ink,
            accent: widget.accent,
            faceFill: widget.faceFill,
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final int hour12;
  final Color ink;
  final Color accent;
  final Color faceFill;

  _DialPainter({required this.hour12, required this.ink, required this.accent, required this.faceFill});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    canvas.drawCircle(center, radius - 1, Paint()..color = faceFill);
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.02,
    );

    for (var i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi;
      final major = i % 3 == 0;
      final outerR = radius - radius * 0.09;
      final innerR = outerR - radius * (major ? 0.14 : 0.07);
      final outer = center + Offset(sin(angle), -cos(angle)) * outerR;
      final inner = center + Offset(sin(angle), -cos(angle)) * innerR;
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = ink
          ..strokeWidth = radius * (major ? 0.03 : 0.015)
          ..strokeCap = StrokeCap.round,
      );
    }

    final handleAngle = (hour12 % 12) / 12 * 2 * pi;
    final handleR = radius - radius * 0.09;
    final handlePos = center + Offset(sin(handleAngle), -cos(handleAngle)) * handleR;

    canvas.drawLine(
      center,
      handlePos,
      Paint()
        ..color = accent
        ..strokeWidth = radius * 0.02
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(handlePos, radius * 0.11, Paint()..color = accent);
    canvas.drawCircle(
      handlePos,
      radius * 0.11,
      Paint()
        ..color = faceFill
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.015,
    );
    canvas.drawCircle(center, radius * 0.025, Paint()..color = ink);
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) =>
      oldDelegate.hour12 != hour12 || oldDelegate.ink != ink || oldDelegate.accent != accent;
}
