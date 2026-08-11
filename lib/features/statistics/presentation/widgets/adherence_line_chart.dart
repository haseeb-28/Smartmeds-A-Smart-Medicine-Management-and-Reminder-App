import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/statistics_models.dart';

class AdherenceLineChart extends StatelessWidget {
  final List<TrendPoint> trend;

  const AdherenceLineChart({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text('No data for this period', style: TextStyle(color: Colors.grey[600])),
        ),
      );
    }

    final primary = Theme.of(context).colorScheme.primary;
    // Thin out x-axis labels for longer trends so they don't overlap.
    final labelInterval = (trend.length / 6).ceil().clamp(1, trend.length);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 1,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: 0.25,
                getTitlesWidget: (value, meta) => Text(
                  '${(value * 100).round()}%',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: labelInterval.toDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= trend.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('M/d').format(trend[index].date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (int i = 0; i < trend.length; i++)
                  FlSpot(i.toDouble(), trend[i].percent),
              ],
              isCurved: true,
              color: primary,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: primary.withValues(alpha: 0.12)),
            ),
          ],
        ),
      ),
    );
  }
}
