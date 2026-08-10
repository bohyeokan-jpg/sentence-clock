import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../model/alarm_config.dart';
import '../model/app_theme.dart';
import '../viewmodel/alarm_provider.dart';
import '../viewmodel/theme_provider.dart';
import 'alarm_edit_screen.dart';

/// Lists the up to 3 alarm slots — tap a row to edit its time/sound
/// (AlarmEditScreen), or flip its switch here for a quick on/off. The clock's
/// single red hand always follows whichever *enabled* row is topmost (see
/// topEnabledAlarm in alarm_provider.dart), so slot order matters.
class AlarmSettingsScreen extends ConsumerWidget {
  const AlarmSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(themePaletteProvider);
    final alarmsAsync = ref.watch(alarmProvider);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        iconTheme: IconThemeData(color: palette.ink),
        title: Text('알람 설정', style: GoogleFonts.notoSerifKr(color: palette.ink, fontSize: 18)),
      ),
      body: alarmsAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: palette.accent)),
        error: (e, st) => Center(child: Text('불러오지 못했어요', style: TextStyle(color: palette.ink))),
        data: (alarms) {
          final topIndex = alarms.indexWhere((a) => a.enabled);
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            itemCount: alarms.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _AlarmRow(
              index: index,
              config: alarms[index],
              palette: palette,
              // Only the topmost enabled row actually drives the clock's red
              // hand — the label makes that visible instead of implicit.
              isShownOnClock: index == topIndex,
              onToggle: (v) => ref.read(alarmProvider.notifier).setEnabled(index, v),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AlarmEditScreen(index: index)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AlarmRow extends StatelessWidget {
  final int index;
  final AlarmConfig config;
  final AppThemePalette palette;
  final bool isShownOnClock;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  const _AlarmRow({
    required this.index,
    required this.config,
    required this.palette,
    required this.isShownOnClock,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hour12 = config.hour % 12 == 0 ? 12 : config.hour % 12;
    final mm = config.minute.toString().padLeft(2, '0');
    final meridiem = config.hour >= 12 ? 'PM' : 'AM';
    final dimmed = !config.enabled;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: palette.ink.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('알람 ${index + 1}',
                          style: GoogleFonts.notoSansKr(
                              fontSize: 11.5, color: palette.ink.withValues(alpha: 0.5))),
                      if (isShownOnClock) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.watch_later_outlined, size: 12, color: palette.accent),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$meridiem $hour12:$mm',
                    maxLines: 1,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: dimmed ? palette.ink.withValues(alpha: 0.35) : palette.ink,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: config.enabled,
              activeTrackColor: palette.accent,
              onChanged: onToggle,
            ),
            Icon(Icons.chevron_right, color: palette.ink.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}
