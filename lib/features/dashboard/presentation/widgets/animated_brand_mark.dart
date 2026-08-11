import 'package:flutter/material.dart';

/// A small entrance animation for the icon in the Dashboard's app bar —
/// fades and slides in from the left on first build. Uses
/// TweenAnimationBuilder (implicit animation) rather than a full
/// AnimationController + StatefulWidget, since this is a one-shot
/// entrance with no need for replay/reverse control.
class AnimatedBrandMark extends StatelessWidget {
  const AnimatedBrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset((1 - value) * -16, 0),
            child: child,
          ),
        );
      },
      child: Image.asset(
        'assets/icon/app_icon.png',
        width: 28,
        height: 28,
        errorBuilder: (_, __, ___) => Icon(
          Icons.medication_liquid,
          size: 26,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
