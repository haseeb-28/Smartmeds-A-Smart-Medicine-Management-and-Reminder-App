import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/settings_models.dart';

/// Both preferences here are stored, but neither is currently wired
/// into how notifications actually play — see the honest note in the
/// Settings screen and README on why. Kept as real, persisted state
/// (not fake UI) so the wiring can be finished later without another
/// migration of user-facing preference data.
class NotificationPrefsController
    extends StateNotifier<({NotificationSoundOption sound, double volume})> {
  NotificationPrefsController()
      : super((sound: NotificationSoundOption.defaultSound, volume: 1.0)) {
    _load();
  }

  static const _soundKey = 'notification_sound';
  static const _volumeKey = 'notification_volume';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSound = prefs.getString(_soundKey);
    final savedVolume = prefs.getDouble(_volumeKey);
    state = (
      sound: savedSound != null
          ? NotificationSoundOption.values
              .firstWhere((e) => e.name == savedSound, orElse: () => state.sound)
          : state.sound,
      volume: savedVolume ?? state.volume,
    );
  }

  Future<void> setSound(NotificationSoundOption sound) async {
    state = (sound: sound, volume: state.volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_soundKey, sound.name);
  }

  Future<void> setVolume(double volume) async {
    state = (sound: state.sound, volume: volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, volume);
  }
}

final notificationPrefsProvider = StateNotifierProvider<
    NotificationPrefsController, ({NotificationSoundOption sound, double volume})>(
  (ref) => NotificationPrefsController(),
);
