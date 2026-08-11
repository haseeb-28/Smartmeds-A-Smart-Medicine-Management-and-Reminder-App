/// Lightweight models for the Dashboard.
/// These mirror what Module 3 (Medicines) and Module 4 (Reminders)
/// will eventually provide from the database — kept separate here so
/// the Dashboard UI can be built and tested before those modules exist.
library;

enum DoseStatus { taken, missed, skipped, upcoming }

class UpcomingDose {
  final String id;
  final String medicineName;
  final String dosageLabel; // e.g. "1 tablet"
  final DateTime time;
  final DoseStatus status;

  const UpcomingDose({
    required this.id,
    required this.medicineName,
    required this.dosageLabel,
    required this.time,
    this.status = DoseStatus.upcoming,
  });
}

class DailyProgress {
  final int takenCount;
  final int totalCount;

  const DailyProgress({required this.takenCount, required this.totalCount});

  double get percent => totalCount == 0 ? 0 : takenCount / totalCount;
  int get percentInt => (percent * 100).round();
}

class DayMarker {
  final DateTime date;
  final DoseStatus dominantStatus;

  const DayMarker({required this.date, required this.dominantStatus});
}

class DashboardSummary {
  final String userName;
  final DailyProgress todayProgress;
  final List<UpcomingDose> upcomingDoses;
  final List<DayMarker> calendarStrip;
  final int currentStreak;
  final double weeklyAdherencePercent;

  const DashboardSummary({
    required this.userName,
    required this.todayProgress,
    required this.upcomingDoses,
    required this.calendarStrip,
    required this.currentStreak,
    required this.weeklyAdherencePercent,
  });
}
