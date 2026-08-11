enum DayStatus { taken, missed, skipped, upcoming, empty }

class CalendarDay {
  final DateTime date;
  final DayStatus status;
  final int doseCount;

  const CalendarDay({
    required this.date,
    required this.status,
    required this.doseCount,
  });
}

/// A single dose row shown when a calendar day is tapped —
/// intentionally simple/display-only, separate from reminders'
/// DoseLog so this module doesn't need to import the reminders feature
/// just to show history.
class DayHistoryEntry {
  final String id;
  final String medicineName;
  final String dosageLabel;
  final DateTime scheduledTime;
  final DateTime? respondedTime;
  final DayStatus status;

  const DayHistoryEntry({
    required this.id,
    required this.medicineName,
    required this.dosageLabel,
    required this.scheduledTime,
    this.respondedTime,
    required this.status,
  });
}
