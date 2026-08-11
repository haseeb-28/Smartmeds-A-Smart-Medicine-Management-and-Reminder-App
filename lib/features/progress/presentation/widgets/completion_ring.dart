import 'package:flutter/material.dart';

class CompletionRing extends StatelessWidget {
  final double percent;
  final int percentInt;
  final double size;

  const CompletionRing({
    super.key,
    required this.percent,
    required this.percentInt,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: 10,
              backgroundColor: primary.withAlpha((0.12 * 255).round()),
              valueColor: AlwaysStoppedAnimation(primary),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percentInt%',
                style: TextStyle(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
              Text(
                'complete',
                style: TextStyle(fontSize: size * 0.09, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
