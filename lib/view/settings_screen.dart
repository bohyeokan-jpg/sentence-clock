import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../model/app_theme.dart';
import '../model/clock_shape.dart';
import '../viewmodel/alarm_provider.dart';
import '../viewmodel/clock_shape_provider.dart';
import '../viewmodel/theme_provider.dart';
import 'alarm_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(themePaletteProvider);
    final currentId = ref.watch(themeProvider);
    final currentShape = ref.watch(clockShapeProvider);
    final alarmAsync = ref.watch(alarmProvider);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        iconTheme: IconThemeData(color: palette.ink),
        title: Text('설정', style: GoogleFonts.notoSerifKr(color: palette.ink, fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '알람',
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AlarmSettingsScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: palette.ink.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.alarm, color: palette.accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: alarmAsync.when(
                        data: (alarms) {
                          final enabledCount = alarms.where((a) => a.enabled).length;
                          final top = topEnabledAlarm(alarms);
                          if (top == null) {
                            return Text('알람 꺼짐', style: GoogleFonts.notoSansKr(fontSize: 12.5, color: palette.ink));
                          }
                          final hour12 = top.hour % 12 == 0 ? 12 : top.hour % 12;
                          final mm = top.minute.toString().padLeft(2, '0');
                          final meridiem = top.hour >= 12 ? 'PM' : 'AM';
                          final extra = enabledCount > 1 ? ' 외 ${enabledCount - 1}개' : '';
                          return Text(
                            '$meridiem $hour12:$mm$extra',
                            maxLines: 1,
                            style: GoogleFonts.notoSansKr(fontSize: 12.5, color: palette.ink), // ~10% smaller (AM/PM vs 오전/오후)
                          );
                        },
                        loading: () => Text('...', style: GoogleFonts.notoSansKr(color: palette.ink)),
                        error: (e, st) => Text('알람', style: GoogleFonts.notoSansKr(color: palette.ink)),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: palette.ink.withValues(alpha: 0.4)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              '테마',
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: AppThemeId.values.map((id) {
                final option = appThemePalettes[id]!;
                final selected = id == currentId;
                return GestureDetector(
                  onTap: () => ref.read(themeProvider.notifier).select(id),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: option.background,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? option.accent : palette.ink.withValues(alpha: 0.15),
                            width: selected ? 3 : 1,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(color: option.accent, shape: BoxShape.circle),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        option.label,
                        style: GoogleFonts.notoSansKr(fontSize: 12, color: palette.ink.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            Text(
              '시계 모양',
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: ClockShape.values.map((shape) {
                final selected = shape == currentShape;
                final label = shape == ClockShape.circle ? '동그란' : '네모난';
                return GestureDetector(
                  onTap: () => ref.read(clockShapeProvider.notifier).select(shape),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: palette.background,
                          shape: shape == ClockShape.circle ? BoxShape.circle : BoxShape.rectangle,
                          borderRadius: shape == ClockShape.square ? BorderRadius.circular(14) : null,
                          border: Border.all(
                            color: selected ? palette.accent : palette.ink.withValues(alpha: 0.15),
                            width: selected ? 3 : 1,
                          ),
                        ),
                        child: Center(
                          child: Container(width: 2, height: 16, color: palette.ink.withValues(alpha: 0.5)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: GoogleFonts.notoSansKr(fontSize: 12, color: palette.ink.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
