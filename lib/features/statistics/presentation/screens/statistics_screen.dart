import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/statistics_provider.dart';
import '../widgets/adherence_line_chart.dart';
import '../widgets/period_selector.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_pie_chart.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(statsPeriodProvider);
    final summaryAsync = ref.watch(statisticsSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PeriodSelector(
              selected: period,
              onChanged: (p) => ref.read(statsPeriodProvider.notifier).state = p,
            ),
            const SizedBox(height: 24),
            summaryAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text('Could not load statistics.')),
              ),
              data: (summary) {
                final avgDelay = summary.averageDelayMinutes;
                final delayLabel = avgDelay.abs() < 1
                    ? 'On time'
                    : avgDelay > 0
                        ? '${avgDelay.round()}m late'
                        : '${avgDelay.abs().round()}m early';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: [
                        StatCard(
                          icon: Icons.check_circle_outline,
                          label: 'Adherence',
                          value: '${(summary.counts.adherencePercent * 100).round()}%',
                          color: Colors.teal,
                        ),
                        StatCard(
                          icon: Icons.cancel_outlined,
                          label: 'Missed Medicines',
                          value: '${summary.counts.missed}',
                          color: Colors.red,
                        ),
                        StatCard(
                          icon: Icons.timer_outlined,
                          label: 'Average Delay',
                          value: delayLabel,
                          color: Colors.orange,
                        ),
                        StatCard(
                          icon: Icons.emoji_events_outlined,
                          label: 'Longest Streak',
                          value: '${summary.longestStreak} days',
                          color: Colors.indigo,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Status Breakdown',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    StatusPieChart(counts: summary.counts),
                    const SizedBox(height: 28),
                    Text(
                      'Adherence Trend',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    AdherenceLineChart(trend: summary.trend),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
