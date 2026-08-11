import 'package:flutter/material.dart';
import '../../data/progress_models.dart';

class ProgressBarChart extends StatelessWidget {
  final List<ProgressPoint> points;
  final double height;

  const ProgressBarChart({super.key, required this.points, this.height = 140});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('No data yet', style: TextStyle(color: Colors.grey[600])),
        ),
      );
    }

    // primary color was unused; remove to silence analyzer.

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((point) {
          final barHeight = (height - 34) * point.percent.clamp(0.0, 1.0);
          final color = point.percent >= 0.8
              ? Colors.green
              : point.percent >= 0.5
                  ? Colors.orange
                  : point.percent > 0
                      ? Colors.red
                      : Colors.grey.shade300;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${(point.percent * 100).round()}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: barHeight < 4 ? 4 : barHeight,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    point.label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
