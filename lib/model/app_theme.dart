import 'package:flutter/material.dart';

enum AppThemeId { cream, black, brown, red }

class AppThemePalette {
  final AppThemeId id;
  final String label;
  final Color background;
  final Color ink;
  final Color accent;

  const AppThemePalette({
    required this.id,
    required this.label,
    required this.background,
    required this.ink,
    required this.accent,
  });
}

/// The four palettes designed in Figma/HTML: cream (default paper look),
/// black (e-ink night mode), brown (wood/leather), red (book-cover red).
const appThemePalettes = <AppThemeId, AppThemePalette>{
  AppThemeId.cream: AppThemePalette(
    id: AppThemeId.cream,
    label: '크림',
    background: Color(0xFFF6F1E7),
    ink: Color(0xFF2B2620),
    accent: Color(0xFF9C7A4A),
  ),
  AppThemeId.black: AppThemePalette(
    id: AppThemeId.black,
    label: '검정',
    background: Color(0xFF141210),
    ink: Color(0xFFF2ECE0),
    accent: Color(0xFFC9A360),
  ),
  AppThemeId.brown: AppThemePalette(
    id: AppThemeId.brown,
    label: '갈색',
    background: Color(0xFF3E2B1F),
    ink: Color(0xFFF5EFE4),
    accent: Color(0xFFD4AF7A),
  ),
  AppThemeId.red: AppThemePalette(
    id: AppThemeId.red,
    label: '적갈색',
    background: Color(0xFF5C2A1D),
    ink: Color(0xFFF5EFE4),
    accent: Color(0xFFD3AF5A),
  ),
};
