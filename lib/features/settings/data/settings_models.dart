enum AppThemeMode { light, dark, system }

extension AppThemeModeX on AppThemeMode {
  String get label {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System Default';
    }
  }
}

enum NotificationSoundOption { defaultSound, silent }

extension NotificationSoundOptionX on NotificationSoundOption {
  String get label {
    switch (this) {
      case NotificationSoundOption.defaultSound:
        return 'Default';
      case NotificationSoundOption.silent:
        return 'Silent';
    }
  }
}

/// Only English is actually wired to real strings. The others render
/// disabled with a "Coming soon" label in the UI — see the Settings
/// screen and the README's honest note on scope. Listed here so the
/// picker UI has real language names to show rather than being empty.
enum AppLanguage { english, urdu, spanish, french }

extension AppLanguageX on AppLanguage {
  String get label {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.urdu:
        return 'اردو (Urdu)';
      case AppLanguage.spanish:
        return 'Español';
      case AppLanguage.french:
        return 'Français';
    }
  }

  bool get isAvailable => this == AppLanguage.english;
}
