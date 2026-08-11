import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../reminders/data/reminder_model.dart' as reminders;
import '../../reminders/providers/reminder_provider.dart';
import '../data/dashboard_models.dart';

DoseStatus _mapStatus(reminders.DoseStatus status) {
  switch (status) {
    case reminders.DoseStatus.taken:
      return DoseStatus.taken;
    case reminders.DoseStatus.missed:
      return DoseStatus.missed;
    case reminders.DoseStatus.skipped:
      return DoseStatus.skipped;
    case reminders.DoseStatus.upcoming:
      return DoseStatus.upcoming;
  }
}

/// Combines auth, today's doses, adherence stats, and the week calendar
/// into the single shape the Dashboard UI expects. This replaces the
/// Module 1/2-era mock data now that Module 4 (Reminders) provides
/// real dose tracking.
final dashboardSummaryProvider = Provider<AsyncValue<DashboardSummary>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final email = repo.currentUser?.email ?? '';
  final displayName = repo.currentUser?.userMetadata?['full_name'] as String? ??
      (email.isNotEmpty ? email.split('@').first : 'there');

  final dosesAsync = ref.watch(todayDosesProvider);
  final statsAsync = ref.watch(adherenceStatsProvider);
  final calendarAsync = ref.watch(weekCalendarProvider);

  if (dosesAsync.isLoading || statsAsync.isLoading || calendarAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (dosesAsync.hasError) {
    return AsyncValue.error(dosesAsync.error!, dosesAsync.stackTrace!);
  }

  final doses = dosesAsync.value ?? [];
  final stats = statsAsync.value ?? (adherencePercent: 0.0, streak: 0);
  final calendar = calendarAsync.value ?? [];

  final takenCount =
      doses.where((d) => d.status == reminders.DoseStatus.taken).length;

  return AsyncValue.data(
    DashboardSummary(
      userName: displayName,
      todayProgress: DailyProgress(
        takenCount: takenCount,
        totalCount: doses.length,
      ),
      upcomingDoses: [
        for (final dose in doses)
          UpcomingDose(
            id: dose.id,
            medicineName: dose.medicineName,
            dosageLabel: dose.dosageLabel,
            time: dose.scheduledTime,
            status: _mapStatus(dose.status),
          ),
      ],
      calendarStrip: [
        for (final day in calendar)
          DayMarker(date: day.date, dominantStatus: _mapStatus(day.status)),
      ],
      currentStreak: stats.streak,
      weeklyAdherencePercent: stats.adherencePercent,
    ),
  );
});
