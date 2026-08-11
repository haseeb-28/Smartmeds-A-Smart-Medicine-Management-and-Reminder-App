import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../main.dart' show AuthGate;

/// Shown immediately after Flutter itself has booted — this is where
/// the actual animation happens, since the NATIVE splash (configured via
/// flutter_native_splash in pubspec.yaml) can only show a static image
/// before Dart code runs at all. This screen picks up right where the
/// native splash leaves off, animates the full logo in, holds briefly,
/// then hands off to Login or Dashboard depending on whether a session
/// already exists.
class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    // Animation itself takes ~900ms; hold a little longer so the logo
    // is actually readable rather than flashing past.
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    // AuthGate already correctly and reactively decides Login vs
    // Dashboard by watching the Supabase auth stream — reusing it here
    // rather than duplicating that session-check logic a second time.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Image.asset(
              'assets/logo/app_logo.png',
              width: 240,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.medication_liquid,
                size: 100,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
