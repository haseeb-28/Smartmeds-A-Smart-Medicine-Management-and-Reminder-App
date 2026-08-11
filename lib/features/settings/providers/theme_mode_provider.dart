import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/settings_models.dart';

/// Dark Mode, persisted the same way Elderly Mode is (Module 13) — a
/// device display preference, not account data.
///
/// Precedence, worth understanding: if Elderly Mode is also on, Elderly
/// Mode's high-contrast light theme wins regardless of what's set here.
/// The two aren't designed to compose (a "dark elderly mode" was judged
/// not worth the added theme-matrix complexity) — see main.dart for
/// where this precedence is actually applied.
class ThemeModeController extends StateNotifier<AppThemeMode> {
  ThemeModeController() : super(AppThemeMode.system) {
    _load();
  }

  static const _prefsKey = 'app_theme_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null) {
      state = AppThemeMode.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => AppThemeMode.system,
      );
    }
  }

  Future<void> setMode(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, AppThemeMode>((ref) {
  return ThemeModeController();
});
