import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/elderly_mode_provider.dart';
import '../../../../core/services/voice_feedback_service.dart';
import '../../../accessibility/presentation/widgets/elderly_dashboard_view.dart';
import '../../../calendar/presentation/screens/calendar_screen.dart';
import '../../../family/presentation/widgets/profile_switcher.dart';
import '../../../medicines/presentation/screens/add_edit_medicine_screen.dart';
import '../../../medicines/presentation/screens/medicine_list_screen.dart';
import '../../../offline/presentation/widgets/offline_banner.dart';
import '../../../progress/presentation/screens/daily_progress_screen.dart';
import '../../../reminders/providers/reminder_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/animated_brand_mark.dart';
import '../widgets/dashboard_drawer.dart';
import '../widgets/greeting_header.dart';
import '../widgets/mini_calendar_strip.dart';
import '../widgets/progress_card.dart';
import '../widgets/section_header.dart';
import '../widgets/stats_summary_row.dart';
import '../widgets/upcoming_medicine_list.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    await ref.read(todayDosesProvider.notifier).load();
    ref.invalidate(adherenceStatsProvider);
    ref.invalidate(weekCalendarProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final isElderlyMode = ref.watch(elderlyModeProvider);

    Future<void> handleTake(String doseId) async {
      final name = summaryAsync.value?.upcomingDoses
          .where((d) => d.id == doseId)
          .firstOrNull
          ?.medicineName;
      await ref.read(todayDosesProvider.notifier).markTaken(doseId);
      if (isElderlyMode) {
        await VoiceFeedbackService.instance
            .speak('${name ?? 'Medicine'} taken. Well done.');
      }
    }

    Future<void> handleSkip(String doseId) async {
      final name = summaryAsync.value?.upcomingDoses
          .where((d) => d.id == doseId)
          .firstOrNull
          ?.medicineName;
      await ref.read(todayDosesProvider.notifier).markSkipped(doseId);
      if (isElderlyMode) {
        await VoiceFeedbackService.instance.speak('${name ?? 'Medicine'} skipped.');
      }
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Row(
          children: [
            AnimatedBrandMark(),
            SizedBox(width: 10),
            Text('SmartMeds'),
          ],
        ),
      ),
      drawer: const DashboardDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEditMedicineScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Quick Add'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: summaryAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 100),
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                const Text(
                  "Couldn't load your dashboard. Pull down to retry.",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            data: (summary) => isElderlyMode
                ? ElderlyDashboardView(
                    userName: summary.userName,
                    doses: summary.upcomingDoses,
                    onTake: handleTake,
                    onSkip: handleSkip,
                  )
                : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const OfflineBanner(),
                GreetingHeader(userName: summary.userName),
                const SizedBox(height: 12),
                const ProfileSwitcher(),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const DailyProgressScreen()),
                    );
                  },
                  child: ProgressCard(
                    progress: summary.todayProgress,
                    streak: summary.currentStreak,
                  ),
                ),
                const SizedBox(height: 24),
                SectionHeader(
                  title: 'This Week',
                  actionLabel: 'View Calendar',
                  onActionTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CalendarScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CalendarScreen()),
                    );
                  },
                  child: MiniCalendarStrip(days: summary.calendarStrip),
                ),
                const SizedBox(height: 24),
                StatsSummaryRow(
                  weeklyAdherencePercent: summary.weeklyAdherencePercent,
                  streak: summary.currentStreak,
                ),
                const SizedBox(height: 24),
                SectionHeader(
                  title: "Today's Medicines",
                  actionLabel: 'See All',
                  onActionTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const MedicineListScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                if (summary.upcomingDoses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No reminders set up yet. Add a medicine and set '
                      'reminder times to see them here.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                else
                  UpcomingMedicineList(
                    doses: summary.upcomingDoses,
                    onTake: handleTake,
                    onSkip: handleSkip,
                  ),
                const SizedBox(height: 80), // room for FAB
              ],
            ),
          ),
        ),
      ),
    );
  }
}