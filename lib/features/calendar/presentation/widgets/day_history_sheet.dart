import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/calendar_models.dart';
import '../../providers/calendar_provider.dart';

class DayHistorySheet extends ConsumerWidget {
  final DateTime day;

  const DayHistorySheet({super.key, required this.day});

  Color _statusColor(DayStatus status) {
    switch (status) {
      case DayStatus.taken:
        return Colors.green;
      case DayStatus.missed:
        return Colors.red;
      case DayStatus.skipped:
        return Colors.orange;
      case DayStatus.upcoming:
      case DayStatus.empty:
        return Colors.blueGrey;
    }
  }

  IconData _statusIcon(DayStatus status) {
    switch (status) {
      case DayStatus.taken:
        return Icons.check_circle;
      case DayStatus.missed:
        return Icons.cancel;
      case DayStatus.skipped:
        return Icons.remove_circle;
      case DayStatus.upcoming:
      case DayStatus.empty:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(dayHistoryProvider(day));

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                DateFormat('EEEE, MMMM d').format(day),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: historyAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) =>
                      const Center(child: Text('Could not load history.')),
                  data: (entries) {
                    if (entries.isEmpty) {
                      return const Center(
                          child: Text('No doses recorded this day.'));
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final color = _statusColor(entry.status);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: Colors.grey.withAlpha((0.15 * 255).round())),
                          ),
                          child: Row(
                            children: [
                              Icon(_statusIcon(entry.status),
                                  color: color, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.medicineName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      entry.dosageLabel,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                DateFormat('h:mm a')
                                    .format(entry.scheduledTime),
                                style: TextStyle(
                                    color: color, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
