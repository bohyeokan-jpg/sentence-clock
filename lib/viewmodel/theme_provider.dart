import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/app_theme.dart';

const _themeKey = 'app_theme_id';

class ThemeNotifier extends Notifier<AppThemeId> {
  @override
  AppThemeId build() {
    _restore();
    return AppThemeId.cream;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeKey);
    if (saved == null) return;
    final match = AppThemeId.values.where((e) => e.name == saved);
    if (match.isNotEmpty) state = match.first;
  }

  Future<void> select(AppThemeId id) async {
    state = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, id.name);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeId>(ThemeNotifier.new);

final themePaletteProvider = Provider<AppThemePalette>((ref) {
  final id = ref.watch(themeProvider);
  return appThemePalettes[id]!;
});
