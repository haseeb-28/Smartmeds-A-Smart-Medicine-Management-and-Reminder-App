enum TimeSlot { morning, afternoon, evening, night }

extension TimeSlotX on TimeSlot {
  String get label {
    switch (this) {
      case TimeSlot.morning:
        return 'Morning';
      case TimeSlot.afternoon:
        return 'Afternoon';
      case TimeSlot.evening:
        return 'Evening';
      case TimeSlot.night:
        return 'Night';
    }
  }

  /// Classifies a time of day into a slot purely by hour — works for
  /// both preset reminder times (Module 4's Morning/Afternoon/etc.)
  /// and custom times, without needing a join back to medicine_schedule.
  static TimeSlot fromHour(int hour) {
    if (hour >= 5 && hour < 12) return TimeSlot.morning;
    if (hour >= 12 && hour < 17) return TimeSlot.afternoon;
    if (hour >= 17 && hour < 21) return TimeSlot.evening;
    return TimeSlot.night;
  }
}

enum SlotOutcome { taken, missed, skipped, upcoming, empty }

class SlotSummary {
  final TimeSlot slot;
  final SlotOutcome outcome;
  final int doseCount;

  const SlotSummary({
    required this.slot,
    required this.outcome,
    required this.doseCount,
  });
}

class DailyProgressBreakdown {
  final DateTime date;
  final List<SlotSummary> slots;
  final int takenCount;
  final int totalCount;

  const DailyProgressBreakdown({
    required this.date,
    required this.slots,
    required this.takenCount,
    required this.totalCount,
  });

  double get completionPercent =>
      totalCount == 0 ? 0 : takenCount / totalCount;
  int get completionPercentInt => (completionPercent * 100).round();
}

class ProgressPoint {
  final String label; // e.g. "Mon" or "Week 1"
  final double percent;

  const ProgressPoint({required this.label, required this.percent});
}
