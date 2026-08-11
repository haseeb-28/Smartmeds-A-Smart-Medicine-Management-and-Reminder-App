import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/history_models.dart';
import '../../providers/history_provider.dart';

class HistoryFilterSheet extends ConsumerWidget {
  const HistoryFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(historyFilterProvider);
    final controller = ref.read(historyFilterProvider.notifier);
    final medicinesAsync = ref.watch(historyMedicineOptionsProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter History',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (!filter.isDefault)
                TextButton(
                  onPressed: controller.clearAll,
                  child: const Text('Clear All'),
                ),
            ],
          ),
          const SizedBox(height: 16),

          Text('Date Range',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(
              filter.dateRange == null
                  ? 'Any date'
                  : '${DateFormat('MMM d').format(filter.dateRange!.start)} – '
                      '${DateFormat('MMM d').format(filter.dateRange!.end)}',
            ),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
                initialDateRange: filter.dateRange,
              );
              if (picked != null) controller.setDateRange(picked);
            },
          ),
          const SizedBox(height: 20),

          Text('Medicine',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          medicinesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Could not load medicines'),
            data: (medicines) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: filter.medicineId == null,
                  onSelected: (_) => controller.setMedicine(null),
                ),
                for (final m in medicines)
                  ChoiceChip(
                    label: Text(m.name),
                    selected: filter.medicineId == m.id,
                    onSelected: (_) => controller.setMedicine(m.id),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text('Status',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: filter.status == null,
                onSelected: (_) => controller.setStatus(null),
              ),
              for (final status in HistoryStatus.values)
                ChoiceChip(
                  label: Text(status.label),
                  selected: filter.status == status,
                  onSelected: (_) => controller.setStatus(status),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}
