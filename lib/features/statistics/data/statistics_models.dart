enum StatsPeriod { week, month, all }

extension StatsPeriodX on StatsPeriod {
  String get label {
    switch (this) {
      case StatsPeriod.week:
        return 'Week';
      case StatsPeriod.month:
        return 'Month';
      case StatsPeriod.all:
        return 'All Time';
    }
  }

  int? get days {
    switch (this) {
      case StatsPeriod.week:
        return 7;
      case StatsPeriod.month:
        return 30;
      case StatsPeriod.all:
        return null; // no lower bound
    }
  }
}

class StatusCounts {
  final int taken;
  final int missed;
  final int skipped;

  const StatusCounts({this.taken = 0, this.missed = 0, this.skipped = 0});

  int get total => taken + missed + skipped;
  double get adherencePercent => total == 0 ? 0 : taken / total;
}

class TrendPoint {
  final DateTime date;
  final double percent;

  const TrendPoint({required this.date, required this.percent});
}

class StatisticsSummary {
  final StatusCounts counts;
  final double averageDelayMinutes;
  final int longestStreak;
  final List<TrendPoint> trend;

  const StatisticsSummary({
    required this.counts,
    required this.averageDelayMinutes,
    required this.longestStreak,
    required this.trend,
  });
}
