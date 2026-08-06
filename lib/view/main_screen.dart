import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../model/app_theme.dart';
import '../model/clock_shape.dart';
import '../viewmodel/alarm_provider.dart';
import '../viewmodel/clock_shape_provider.dart';
import '../viewmodel/quote_provider.dart';
import '../viewmodel/theme_provider.dart';
import '../widget/clock_widget.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(themePaletteProvider);
    final clockShape = ref.watch(clockShapeProvider);
    final quoteState = ref.watch(quoteProvider);
    final alarmAsync = ref.watch(alarmProvider);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isLandscape ? 40 : 28, vertical: isLandscape ? 16 : 24),
              child: isLandscape
                  ? _SplitBody(palette: palette, quoteState: quoteState, clockShape: clockShape)
                  : _PortraitBody(palette: palette, quoteState: quoteState, clockShape: clockShape),
            ),
            if (alarmAsync.value?.enabled == true)
              Positioned(
                top: isLandscape ? 4 : 0,
                left: 0,
                child: _AlarmBadge(palette: palette, hour: alarmAsync.value!.hour, minute: alarmAsync.value!.minute),
              ),
            Positioned(
              top: isLandscape ? 4 : 0,
              right: 0,
              child: IconButton(
                icon: Icon(Icons.settings_outlined, color: palette.ink.withValues(alpha: 0.55)),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clock on top, quote below, centered — the vertical form for portrait.
class _PortraitBody extends StatelessWidget {
  final AppThemePalette palette;
  final AsyncValue<QuoteState> quoteState;
  final ClockShape clockShape;

  const _PortraitBody({required this.palette, required this.quoteState, required this.clockShape});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 44),
                  const Spacer(),
                  ClockWidget(ink: palette.ink, accent: palette.accent, faceFill: palette.background, shape: clockShape),
                  const Spacer(),
                  _QuoteBlock(
                    palette: palette,
                    quoteState: quoteState,
                    align: CrossAxisAlignment.center,
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  _FooterNote(palette: palette),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Clock on the left, quote on the right — the fixed side-by-side layout
/// of the physical Author Clock's wide e-paper screen, used in landscape.
class _SplitBody extends StatelessWidget {
  final AppThemePalette palette;
  final AsyncValue<QuoteState> quoteState;
  final ClockShape clockShape;

  const _SplitBody({required this.palette, required this.quoteState, required this.clockShape});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 500;
        final clockSize = compact ? 180.0 : 203.0;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClockWidget(
                    ink: palette.ink,
                    accent: palette.accent,
                    faceFill: palette.background,
                    faceSize: clockSize,
                    digitalFontSize: compact ? 24 : 30,
                    shape: clockShape,
                  ),
                  SizedBox(width: compact ? 20 : 36),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _QuoteBlock(
                          palette: palette,
                          quoteState: quoteState,
                          align: CrossAxisAlignment.start,
                          textAlign: TextAlign.left,
                          fontSize: compact ? 16 : 21,
                        ),
                        const SizedBox(height: 14),
                        _FooterNote(palette: palette),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuoteBlock extends StatelessWidget {
  final AppThemePalette palette;
  final AsyncValue<QuoteState> quoteState;
  final CrossAxisAlignment align;
  final TextAlign textAlign;
  final double fontSize;

  const _QuoteBlock({
    required this.palette,
    required this.quoteState,
    required this.align,
    required this.textAlign,
    this.fontSize = 21,
  });

  @override
  Widget build(BuildContext context) {
    return quoteState.when(
      data: (state) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: align,
        children: [
          Text(
            '"${state.quote.text}"',
            textAlign: textAlign,
            style: GoogleFonts.notoSerifKr(
              fontSize: fontSize,
              height: 1.55,
              fontWeight: FontWeight.w500,
              color: palette.ink,
            ),
          ),
          if (state.quote.attribution != null) ...[
            const SizedBox(height: 16),
            Container(width: 28, height: 1.5, color: palette.accent),
            const SizedBox(height: 12),
            Text(
              state.quote.attribution!,
              style: GoogleFonts.notoSansKr(fontSize: 13, color: palette.ink.withValues(alpha: 0.65)),
            ),
          ],
        ],
      ),
      loading: () => SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: palette.accent),
      ),
      error: (err, st) => Text('문장을 불러오지 못했어요', style: TextStyle(color: palette.ink)),
    );
  }
}

class _AlarmBadge extends StatelessWidget {
  final AppThemePalette palette;
  final int hour;
  final int minute;

  const _AlarmBadge({required this.palette, required this.hour, required this.minute});

  @override
  Widget build(BuildContext context) {
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final mm = minute.toString().padLeft(2, '0');
    final meridiem = hour >= 12 ? '오후' : '오전';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: palette.accent),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.alarm, size: 12, color: palette.accent),
          const SizedBox(width: 5),
          Text(
            '$meridiem $hour12:$mm',
            style: GoogleFonts.notoSansKr(
              fontSize: 11.5,
              color: palette.accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  final AppThemePalette palette;
  const _FooterNote({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Text(
      '1분마다 새 문장',
      style: GoogleFonts.notoSansKr(fontSize: 11, color: palette.ink.withValues(alpha: 0.35)),
    );
  }
}
