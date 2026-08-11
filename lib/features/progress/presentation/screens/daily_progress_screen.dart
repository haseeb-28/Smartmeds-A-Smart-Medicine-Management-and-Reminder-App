import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/progress_provider.dart';
import '../widgets/completion_ring.dart';
import '../widgets/progress_bar_chart.dart';
import '../widgets/time_slot_row.dart';

class DailyProgressScreen extends ConsumerWidget {
  const DailyProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Progress'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Today'),
              Tab(text: 'Weekly'),
              Tab(text: 'Monthly'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TodayTab(),
            _WeeklyTab(),
            _MonthlyTab(),
          ],
        ),
      ),
    );
  }
}

class _TodayTab extends ConsumerWidget {
  const _TodayTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(dailyProgressProvider);

    return breakdownAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Could not load progress.')),
      data: (breakdown) {
        if (breakdown.totalCount == 0) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 80),
              Icon(Icons.bar_chart, size: 56, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No doses scheduled today',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Set up reminder times on a medicine to start tracking progress.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: CompletionRing(
                percent: breakdown.completionPercent,
                percentInt: breakdown.completionPercentInt,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${breakdown.takenCount} of ${breakdown.totalCount} medicines taken today',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'By Time of Day',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            for (final slot in breakdown.slots) TimeSlotRow(summary: slot),
          ],
        );
      },
    );
  }
}

class _WeeklyTab extends ConsumerWidget {
  const _WeeklyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyProgressProvider);

    return weeklyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Could not load progress.')),
      data: (points) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Last 7 Days',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          ProgressBarChart(points: points),
        ],
      ),
    );
  }
}

class _MonthlyTab extends ConsumerWidget {
  const _MonthlyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyAsync = ref.watch(monthlyProgressProvider);

    return monthlyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Could not load progress.')),
      data: (points) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'This Month, by Week',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          ProgressBarChart(points: points),
        ],
      ),
    );
  }
}
