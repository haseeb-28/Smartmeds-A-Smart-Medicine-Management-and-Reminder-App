import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../data/statistics_models.dart';

class StatusPieChart extends StatelessWidget {
  final StatusCounts counts;

  const StatusPieChart({super.key, required this.counts});

  @override
  Widget build(BuildContext context) {
    if (counts.total == 0) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text('No data for this period', style: TextStyle(color: Colors.grey[600])),
        ),
      );
    }

    return Row(
      children: [
        SizedBox(
          height: 160,
          width: 160,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: [
                if (counts.taken > 0)
                  PieChartSectionData(
                    value: counts.taken.toDouble(),
                    color: Colors.green,
                    title: '${counts.taken}',
                    radius: 44,
                    titleStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                if (counts.missed > 0)
                  PieChartSectionData(
                    value: counts.missed.toDouble(),
                    color: Colors.red,
                    title: '${counts.missed}',
                    radius: 44,
                    titleStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                if (counts.skipped > 0)
                  PieChartSectionData(
                    value: counts.skipped.toDouble(),
                    color: Colors.orange,
                    title: '${counts.skipped}',
                    radius: 44,
                    titleStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _LegendRow(color: Colors.green, label: 'Taken', count: counts.taken),
              const SizedBox(height: 8),
              _LegendRow(color: Colors.red, label: 'Missed', count: counts.missed),
              const SizedBox(height: 8),
              _LegendRow(color: Colors.orange, label: 'Skipped', count: counts.skipped),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendRow({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text('$label ($count)', style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
