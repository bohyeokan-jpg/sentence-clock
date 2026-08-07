import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../model/clock_shape.dart';
import 'analog_clock_painter.dart';

/// Analog + digital clock, ticking every second. Kept as one widget so it
/// can be reused verbatim across the main screen and (later) widgets/alarm
/// screens, matching the "Clock / Analog + Digital" component from Figma.
class ClockWidget extends StatefulWidget {
  final Color ink;
  final Color accent;
  final Color faceFill;
  final double faceSize;
  final double digitalFontSize;
  final ClockShape shape;

  /// Color for the dial's rim/ticks/numerals/hands. Defaults to [ink], but
  /// since [faceFill] is now a bold color deliberately far from the screen
  /// background (not a subtle tint of it), the dial needs its own color
  /// that reads against *that* — pass the theme's `background` for that
  /// (see [AppThemePalette.clockDialInk]), not the digital text's ink.
  final Color? dialInk;

  /// Alarm time to mark with a red hand, or null to hide it (alarm off).
  final int? alarmHour;
  final int? alarmMinute;

  const ClockWidget({
    super.key,
    required this.ink,
    required this.accent,
    required this.faceFill,
    this.faceSize = 263,
    this.digitalFontSize = 34, // ~10% smaller now that it reads "AM/PM h:mm:ss" instead of "오전 h:mm:ss"
    this.shape = ClockShape.circle,
    this.dialInk,
    this.alarmHour,
    this.alarmMinute,
  });

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _scheduleNextTick();
  }

  void _scheduleNextTick() {
    final delay = Duration(milliseconds: 1000 - _now.millisecond);
    _timer = Timer(delay, () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _scheduleNextTick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _digital(DateTime t) {
    final meridiem = t.hour < 12 ? 'AM' : 'PM';
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final mm = t.minute.toString().padLeft(2, '0');
    final ss = t.second.toString().padLeft(2, '0');
    return '$meridiem $hour12:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.faceSize,
          height: widget.faceSize,
          child: CustomPaint(
            painter: AnalogClockPainter(
              time: _now,
              ink: widget.dialInk ?? widget.ink,
              accent: widget.accent,
              faceFill: widget.faceFill,
              shape: widget.shape,
              alarmHour: widget.alarmHour,
              alarmMinute: widget.alarmMinute,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _digital(_now),
          style: GoogleFonts.notoSansKr(
            fontSize: widget.digitalFontSize,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
            color: widget.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
