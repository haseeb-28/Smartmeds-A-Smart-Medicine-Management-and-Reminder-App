import 'package:flutter/material.dart';

/// Colors pulled directly from the SmartMeds logo (blue-to-teal capsule,
/// cyan ring, green leaf accent) so the app's UI actually matches the
/// brand assets rather than using a generic single-seed teal.
class AppColors {
  AppColors._();

  static const Color brandBlue = Color(0xFF1247B0); // capsule top / wordmark
  static const Color brandTeal = Color(0xFF2FC2C2); // ring / heart accent
  static const Color brandGreen = Color(0xFF5CB860); // leaf accent
  static const Color splashBackground = Color(0xFF0D3B8C); // deep blue, matches icon bg
}
