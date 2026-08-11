import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../reminders/providers/reminder_provider.dart';
import '../data/progress_models.dart';
import '../data/progress_repository.dart';

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository();
});

final dailyProgressProvider = FutureProvider<DailyProgressBreakdown>((ref) {
  // Recompute whenever today's doses change (a Take Now/Skip tap should
  // be reflected here immediately, not just on the Dashboard).
  ref.watch(todayDosesProvider);
  return ref.watch(progressRepositoryProvider).fetchDailyBreakdown();
});

final weeklyProgressProvider = FutureProvider<List<ProgressPoint>>((ref) {
  ref.watch(todayDosesProvider);
  return ref.watch(progressRepositoryProvider).fetchWeeklyProgress();
});

final monthlyProgressProvider = FutureProvider<List<ProgressPoint>>((ref) {
  ref.watch(todayDosesProvider);
  return ref.watch(progressRepositoryProvider).fetchMonthlyProgress();
});
