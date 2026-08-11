import 'package:flutter/material.dart';
import '../../data/calendar_models.dart';
import 'day_cell.dart';

class MonthGrid extends StatelessWidget {
  final DateTime month;
  final List<CalendarDay> days;
  final void Function(CalendarDay day) onDayTap;

  const MonthGrid({
    super.key,
    required this.month,
    required this.days,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    // Monday = 1 ... Sunday = 7 → leading blanks so day 1 lands under
    // the correct weekday column.
    final leadingBlanks = firstDayOfMonth.weekday - 1;
    final now = DateTime.now();

    const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: [
        Row(
          children: weekdayLabels
              .map((label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1,
          children: [
            for (int i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
            for (final day in days)
              DayCell(
                day: day,
                isToday: day.date.year == now.year &&
                    day.date.month == now.month &&
                    day.date.day == now.day,
                onTap: () => onDayTap(day),
              ),
          ],
        ),
      ],
    );
  }
}
