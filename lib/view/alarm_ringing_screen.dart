import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../viewmodel/alarm_provider.dart';
import '../viewmodel/theme_provider.dart';

class AlarmRingingScreen extends ConsumerStatefulWidget {
  final AlarmSettings alarmSettings;
  const AlarmRingingScreen({super.key, required this.alarmSettings});

  @override
  ConsumerState<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends ConsumerState<AlarmRingingScreen> {
  bool _dismissing = false;

  // Guarded so tap-anywhere and the button (which both hit-test the same
  // pointer) can never fire Alarm.stop / Navigator.pop twice.
  Future<void> _dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    await Alarm.stop(widget.alarmSettings.id);
    await ref.read(alarmProvider.notifier).reschedule(widget.alarmSettings.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(themePaletteProvider);
    final now = TimeOfDay.now();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _dismiss();
      },
      child: Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _dismiss,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_active_outlined, size: 56, color: palette.accent),
                  const SizedBox(height: 20),
                  Text(
                    now.format(context),
                    style: GoogleFonts.notoSansKr(fontSize: 40, fontWeight: FontWeight.w600, color: palette.ink),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '일어날 시간이에요',
                    style: GoogleFonts.notoSerifKr(fontSize: 18, color: palette.ink),
                  ),
                  const SizedBox(height: 56),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.accent,
                        foregroundColor: palette.background,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _dismiss,
                      child: Text('알람 끄기', style: GoogleFonts.notoSansKr(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '화면 아무 곳이나 눌러도 꺼져요',
                    style: GoogleFonts.notoSansKr(fontSize: 13, color: palette.ink.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
