import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Elderly Mode is a device-display preference (large text, high
/// contrast, bigger touch targets), not account data, so it's stored
/// locally via shared_preferences rather than synced through Supabase —
/// consistent with how most apps treat accessibility/display settings.
class ElderlyModeController extends StateNotifier<bool> {
  ElderlyModeController() : super(false) {
    _load();
  }

  static const _prefsKey = 'elderly_mode_enabled';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_prefsKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
  }

  Future<void> toggle() => setEnabled(!state);
}

final elderlyModeProvider =
    StateNotifierProvider<ElderlyModeController, bool>((ref) {
  return ElderlyModeController();
});
