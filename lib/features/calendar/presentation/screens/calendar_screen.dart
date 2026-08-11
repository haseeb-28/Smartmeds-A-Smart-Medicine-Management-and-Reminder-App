import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/calendar_provider.dart';
import '../widgets/calendar_legend.dart';
import '../widgets/day_history_sheet.dart';
import '../widgets/month_grid.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final daysAsync = ref.watch(monthDaysProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      ref.read(selectedMonthProvider.notifier).state =
                          DateTime(month.year, month.month - 1, 1);
                    },
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(month),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      ref.read(selectedMonthProvider.notifier).state =
                          DateTime(month.year, month.month + 1, 1);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const CalendarLegend(),
              const SizedBox(height: 20),
              Expanded(
                child: daysAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) =>
                      const Center(child: Text('Could not load calendar.')),
                  data: (days) => SingleChildScrollView(
                    child: MonthGrid(
                      month: month,
                      days: days,
                      onDayTap: (day) {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20)),
                          ),
                          builder: (_) => DayHistorySheet(day: day.date),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
