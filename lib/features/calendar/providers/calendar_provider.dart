import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/calendar_models.dart';
import '../data/calendar_repository.dart';

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository();
});

/// Currently viewed month (defaults to this month). Changing this drives
/// which month's data `monthDaysProvider` fetches.
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final monthDaysProvider = FutureProvider<List<CalendarDay>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(calendarRepositoryProvider).fetchMonthDays(month);
});

final dayHistoryProvider =
    FutureProvider.family<List<DayHistoryEntry>, DateTime>((ref, day) {
  return ref.watch(calendarRepositoryProvider).fetchDayHistory(day);
});
