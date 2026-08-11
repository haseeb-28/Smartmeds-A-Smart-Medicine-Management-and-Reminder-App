import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../family/providers/family_provider.dart';
import '../data/statistics_models.dart';
import '../data/statistics_repository.dart';

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepository();
});

final statsPeriodProvider = StateProvider<StatsPeriod>((ref) => StatsPeriod.week);

final statisticsSummaryProvider = FutureProvider<StatisticsSummary>((ref) {
  final profile = ref.watch(selectedProfileProvider);
  final period = ref.watch(statsPeriodProvider);
  if (profile == null) {
    return Future.value(
      const StatisticsSummary(
        counts: StatusCounts(),
        averageDelayMinutes: 0,
        longestStreak: 0,
        trend: [],
      ),
    );
  }
  return ref.watch(statisticsRepositoryProvider).fetchSummary(profile.id, period);
});
