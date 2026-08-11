import 'package:flutter/material.dart';
import '../../data/calendar_models.dart';

class DayCell extends StatelessWidget {
  final CalendarDay day;
  final bool isToday;
  final VoidCallback onTap;

  const DayCell({
    super.key,
    required this.day,
    required this.isToday,
    required this.onTap,
  });

  Color? get _backgroundColor {
    switch (day.status) {
      case DayStatus.taken:
        return Colors.green.withAlpha((0.18 * 255).round());
      case DayStatus.missed:
        return Colors.red.withAlpha((0.18 * 255).round());
      case DayStatus.skipped:
        return Colors.orange.withAlpha((0.18 * 255).round());
      case DayStatus.upcoming:
      case DayStatus.empty:
        return null;
    }
  }

  Color get _textColor {
    switch (day.status) {
      case DayStatus.taken:
        return Colors.green.shade800;
      case DayStatus.missed:
        return Colors.red.shade800;
      case DayStatus.skipped:
        return Colors.orange.shade800;
      case DayStatus.upcoming:
      case DayStatus.empty:
        return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: day.doseCount > 0 ? onTap : null,
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: _backgroundColor,
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.date.day}',
          style: TextStyle(
            color: _textColor,
            fontWeight: isToday || day.status != DayStatus.empty
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
