import 'package:flutter/material.dart';
import '../../data/dashboard_models.dart';

class MiniCalendarStrip extends StatelessWidget {
  final List<DayMarker> days;

  const MiniCalendarStrip({super.key, required this.days});

  Color _statusColor(DoseStatus status) {
    switch (status) {
      case DoseStatus.taken:
        return Colors.green;
      case DoseStatus.missed:
        return Colors.red;
      case DoseStatus.skipped:
        return Colors.orange;
      case DoseStatus.upcoming:
        return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    const weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((day) {
        final isToday = day.date.year == today.year &&
            day.date.month == today.month &&
            day.date.day == today.day;
        final color = _statusColor(day.dominantStatus);

        return Column(
          children: [
            Text(
              weekdayLabels[(day.date.weekday - 1) % 7],
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 6),
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withAlpha((0.15 * 255).round()),
                border: Border.all(
                  color: isToday ? Theme.of(context).colorScheme.primary : color,
                  width: isToday ? 2 : 1.5,
                ),
              ),
              child: Text(
                '${day.date.day}',
                style: TextStyle(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
