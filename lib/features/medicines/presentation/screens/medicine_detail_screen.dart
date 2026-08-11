import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/medicine_model.dart';
import '../../providers/medicine_provider.dart';
import '../../../reminders/presentation/screens/reminder_settings_screen.dart';
import 'add_edit_medicine_screen.dart';

class MedicineDetailScreen extends ConsumerWidget {
  final Medicine medicine;

  const MedicineDetailScreen({super.key, required this.medicine});

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(medicineListProvider.notifier);
    final isPaused = medicine.status == MedicineStatus.paused;

    return Scaffold(
      appBar: AppBar(
        title: Text(medicine.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AddEditMedicineScreen(existingMedicine: medicine),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _DetailRow(label: 'Brand Name', value: medicine.brandName ?? '—'),
          _DetailRow(label: 'Generic Name', value: medicine.genericName ?? '—'),
          _DetailRow(label: 'Dosage Form', value: medicine.dosageForm.label),
          _DetailRow(label: 'Meal Timing', value: medicine.mealTiming.label),
          _DetailRow(
            label: 'Stock',
            value:
                '${medicine.quantityRemaining} of ${medicine.quantityTotal} remaining',
            valueColor: medicine.isOutOfStock
                ? Colors.red
                : medicine.isLowStock
                    ? Colors.orange
                    : null,
          ),
          _DetailRow(label: 'Start Date', value: _formatDate(medicine.startDate)),
          _DetailRow(
            label: 'End Date',
            value: medicine.endDate != null
                ? _formatDate(medicine.endDate!)
                : 'Ongoing',
          ),
          if (medicine.notes != null && medicine.notes!.isNotEmpty)
            _DetailRow(label: 'Notes', value: medicine.notes!),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReminderSettingsScreen(
                    medicineId: medicine.id,
                    medicineName: medicine.name,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.alarm_add_outlined),
            label: const Text('Manage Reminders'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              if (isPaused) {
                await controller.resumeMedicine(medicine.id);
              } else {
                await controller.pauseMedicine(medicine.id);
              }
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
            label: Text(isPaused ? 'Resume Medicine' : 'Pause Medicine'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await controller.archiveMedicine(medicine.id);
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Archive Medicine'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Medicine?'),
                  content: Text(
                      'This will permanently delete ${medicine.name} and its history. This cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await controller.deleteMedicine(medicine.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Medicine'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
