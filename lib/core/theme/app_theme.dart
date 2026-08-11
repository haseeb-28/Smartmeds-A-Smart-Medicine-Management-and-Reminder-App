import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Three ThemeData variants, all built from the actual brand palette
/// (see app_colors.dart) rather than a single generic seed color, so
/// buttons, app bars, and highlights genuinely match the logo/icon
/// instead of just being "a" teal that happens to be in the right family.
///
/// Elderly Mode's font/button/contrast changes cascade automatically to
/// every already-built screen through Flutter's Theme inheritance — no
/// need to touch each feature screen individually for those three PRD
/// items (Large Font, Large Buttons, High Contrast). Simple Navigation /
/// Minimal Interface, by contrast, are layout decisions that can't be
/// theme-driven — see the Dashboard's simplified layout branch.
class AppTheme {
  AppTheme._();

  static ColorScheme _brandScheme(Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: AppColors.brandBlue,
      brightness: brightness,
      secondary: AppColors.brandTeal,
      tertiary: AppColors.brandGreen,
    );
  }

  static ThemeData standard() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _brandScheme(Brightness.light),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _brandScheme(Brightness.dark),
    );
  }

  static ThemeData elderly() {
    final base = ThemeData(
      useMaterial3: true,
      // Only colorScheme is passed here, not colorSchemeSeed — Flutter's
      // ThemeData asserts the two are never both provided at once.
      colorScheme: _brandScheme(Brightness.light).copyWith(
        // High Contrast: pure black text on white, not the softer greys
        // used elsewhere in the app — deliberately less "designed," more
        // legible for low-vision users. Primary kept close to brand blue
        // but darkened slightly for better contrast against white.
        surface: Colors.white,
        onSurface: Colors.black,
        primary: const Color(0xFF0B2E6B),
      ),
    );

    return base.copyWith(
      // Large Font itself is handled by MediaQuery.textScaler in
      // main.dart, not here — a TextTheme.apply(fontSizeFactor: ...)
      // approach was tried and removed, since Material 3's default
      // typography includes at least one style with a null fontSize,
      // which apply() asserts against and crashes on.
      // Large Buttons: bigger minimum touch targets app-wide.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(88, 60),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(88, 60),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(88, 60),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      iconTheme: const IconThemeData(size: 32),
      appBarTheme: const AppBarTheme(
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}
