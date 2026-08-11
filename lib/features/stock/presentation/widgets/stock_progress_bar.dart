import 'package:flutter/material.dart';
import '../../data/stock_models.dart';

class StockProgressBar extends StatelessWidget {
  final int remaining;
  final int total;

  const StockProgressBar({super.key, required this.remaining, required this.total});

  Color _colorFor(StockLevel level) {
    switch (level) {
      case StockLevel.normal:
        return Colors.green;
      case StockLevel.low:
        return Colors.orange;
      case StockLevel.out:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = StockLevelX.classify(remaining);
    final color = _colorFor(level);
    final percent = total == 0 ? 0.0 : (remaining / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: Colors.grey.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          level == StockLevel.out
              ? 'Out of stock'
              : '$remaining of $total remaining',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight:
                level == StockLevel.normal ? FontWeight.normal : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
