import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../model/alarm_config.dart';
import '../model/alarm_sound.dart';
import '../model/app_theme.dart';
import '../viewmodel/alarm_provider.dart';
import '../viewmodel/theme_provider.dart';
import '../widget/circular_hour_picker.dart';

enum _InputMode { dial, digital }

class AlarmSettingsScreen extends ConsumerStatefulWidget {
  const AlarmSettingsScreen({super.key});

  @override
  ConsumerState<AlarmSettingsScreen> createState() => _AlarmSettingsScreenState();
}

class _AlarmSettingsScreenState extends ConsumerState<AlarmSettingsScreen> {
  _InputMode _mode = _InputMode.dial;
  late int _hour12;
  late bool _isPm;
  late int _minute;
  late String _soundId;
  bool _initialized = false;

  final _player = AudioPlayer();
  String? _previewingId;

  void _initFrom(AlarmConfig config) {
    if (_initialized) return;
    final hour24 = config.hour;
    _isPm = hour24 >= 12;
    _hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    _minute = config.minute;
    _soundId = config.soundId;
    _initialized = true;
  }

  int get _hour24 {
    final base = _hour12 % 12;
    return _isPm ? base + 12 : base;
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePreview(AlarmSound sound) async {
    if (_previewingId == sound.id) {
      await _player.stop();
      setState(() => _previewingId = null);
      return;
    }
    await _player.stop();
    await _player.play(AssetSource(sound.assetPath.replaceFirst('assets/', '')));
    setState(() => _previewingId = sound.id);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(themePaletteProvider);
    final alarmAsync = ref.watch(alarmProvider);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        iconTheme: IconThemeData(color: palette.ink),
        title: Text('알람 설정', style: GoogleFonts.notoSerifKr(color: palette.ink, fontSize: 18)),
      ),
      body: alarmAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: palette.accent)),
        error: (e, st) => Center(child: Text('불러오지 못했어요', style: TextStyle(color: palette.ink))),
        data: (config) {
          _initFrom(config);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(config.enabled ? '알람 켜짐' : '알람 꺼짐',
                        style: GoogleFonts.notoSansKr(fontSize: 14, color: palette.ink)),
                    Switch(
                      value: config.enabled,
                      activeTrackColor: palette.accent,
                      onChanged: (v) => ref.read(alarmProvider.notifier).setEnabled(v),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _segmentedControl(palette),
                const SizedBox(height: 24),
                Center(
                  child: _mode == _InputMode.dial ? _dialPicker(palette) : _digitalPicker(palette),
                ),
                const SizedBox(height: 28),
                Text('알람 사운드',
                    style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.w600, color: palette.ink)),
                const SizedBox(height: 12),
                _soundGroup(palette, '클래식', AlarmSoundCategory.classical),
                const SizedBox(height: 14),
                _soundGroup(palette, '부드러운 음악', AlarmSoundCategory.soft),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: palette.background,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      await _player.stop();
                      await ref.read(alarmProvider.notifier).save(
                            config.copyWith(enabled: true, hour: _hour24, minute: _minute, soundId: _soundId),
                          );
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: Text('저장', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _segmentedControl(AppThemePalette palette) {
    Widget tab(String label, _InputMode mode) {
      final active = _mode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _mode = mode),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: active ? palette.accent : null),
            alignment: Alignment.center,
            child: Text(
              label,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: active ? palette.background : palette.ink,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: palette.accent),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(children: [tab('다이얼로 설정', _InputMode.dial), tab('숫자로 설정', _InputMode.digital)]),
    );
  }

  Widget _dialPicker(AppThemePalette palette) {
    return Column(
      children: [
        CircularHourPicker(
          hour12: _hour12,
          onChanged: (h) => setState(() => _hour12 = h),
          ink: palette.ink,
          accent: palette.accent,
          faceFill: palette.background,
        ),
        const SizedBox(height: 14),
        _timeLabel(palette),
        const SizedBox(height: 14),
        _amPmToggle(palette),
        const SizedBox(height: 10),
        _minuteChips(palette),
      ],
    );
  }

  Widget _digitalPicker(AppThemePalette palette) {
    Widget stepper(String value, VoidCallback onUp, VoidCallback onDown) {
      return Column(
        children: [
          IconButton(icon: Icon(Icons.keyboard_arrow_up, color: palette.accent), onPressed: onUp),
          Text(value,
              style: GoogleFonts.notoSansKr(fontSize: 34, fontWeight: FontWeight.w600, color: palette.ink)),
          IconButton(icon: Icon(Icons.keyboard_arrow_down, color: palette.accent), onPressed: onDown),
        ],
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            stepper(
              _hour12.toString().padLeft(2, '0'),
              () => setState(() => _hour12 = _hour12 % 12 + 1),
              () => setState(() => _hour12 = (_hour12 + 10) % 12 + 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(':', style: GoogleFonts.notoSansKr(fontSize: 30, fontWeight: FontWeight.w600, color: palette.ink)),
            ),
            stepper(
              _minute.toString().padLeft(2, '0'),
              () => setState(() => _minute = (_minute + 1) % 60),
              () => setState(() => _minute = (_minute + 59) % 60),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _amPmToggle(palette),
      ],
    );
  }

  Widget _timeLabel(AppThemePalette palette) {
    final mm = _minute.toString().padLeft(2, '0');
    return Text('${_isPm ? 'PM' : 'AM'} $_hour12:$mm',
        maxLines: 1,
        style: GoogleFonts.notoSansKr(
            fontSize: 18, fontWeight: FontWeight.w600, color: palette.ink)); // ~10% smaller (AM/PM vs 오전/오후)
  }

  Widget _amPmToggle(AppThemePalette palette) {
    Widget chip(String label, bool value) {
      final active = _isPm == value;
      return GestureDetector(
        onTap: () => setState(() => _isPm = value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: active ? palette.accent : null,
            border: Border.all(color: palette.accent),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label,
              style: GoogleFonts.notoSansKr(
                  fontSize: 12, color: active ? palette.background : palette.ink)),
        ),
      );
    }

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [chip('AM', false), chip('PM', true)]);
  }

  Widget _minuteChips(AppThemePalette palette) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [0, 15, 30, 45].map((m) {
        final active = _minute == m;
        return GestureDetector(
          onTap: () => setState(() => _minute = m),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: active ? palette.accent : null,
              border: Border.all(color: palette.accent),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('${m.toString().padLeft(2, '0')}분',
                style: GoogleFonts.notoSansKr(fontSize: 11, color: active ? palette.background : palette.ink)),
          ),
        );
      }).toList(),
    );
  }

  Widget _soundGroup(AppThemePalette palette, String label, AlarmSoundCategory category) {
    final sounds = alarmSoundCatalog.where((s) => s.category == category).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.notoSansKr(
                fontSize: 10.5,
                letterSpacing: 0.5,
                color: palette.ink.withValues(alpha: 0.55))),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sounds.map((sound) {
            final selected = _soundId == sound.id;
            final previewing = _previewingId == sound.id;
            return GestureDetector(
              onTap: () => setState(() => _soundId = sound.id),
              child: Container(
                padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
                decoration: BoxDecoration(
                  color: selected ? palette.accent : null,
                  border: Border.all(color: palette.accent),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(sound.label,
                        style: GoogleFonts.notoSansKr(
                            fontSize: 12, color: selected ? palette.background : palette.ink)),
                    const SizedBox(width: 2),
                    IconButton(
                      iconSize: 16,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      icon: Icon(
                        previewing ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                        color: selected ? palette.background : palette.accent,
                      ),
                      onPressed: () => _togglePreview(sound),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
