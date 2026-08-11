import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/settings_models.dart';

/// Stores the choice for real, but only AppLanguage.english actually
/// changes anything — see settings_models.dart's isAvailable and the
/// Settings screen's disabled-option UI. Not wired to flutter_localizations
/// or any ARB translation files; every string in this app is hardcoded
/// English across all ~16 modules. Retrofitting real i18n would mean
/// wrapping every user-facing string app-wide, which is a large,
/// separate effort, not something this module does silently or partially.
class LanguageController extends StateNotifier<AppLanguage> {
  LanguageController() : super(AppLanguage.english) {
    _load();
  }

  static const _prefsKey = 'app_language';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null) {
      state = AppLanguage.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => AppLanguage.english,
      );
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language.name);
  }
}

final languageProvider =
    StateNotifierProvider<LanguageController, AppLanguage>((ref) {
  return LanguageController();
});
