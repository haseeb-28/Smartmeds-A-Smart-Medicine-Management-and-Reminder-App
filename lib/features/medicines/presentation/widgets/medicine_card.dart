import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/medicine_model.dart';

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onTap;
  final VoidCallback onPauseResume;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const MedicineCard({
    super.key,
    required this.medicine,
    required this.onTap,
    required this.onPauseResume,
    required this.onArchive,
    required this.onDelete,
  });

  IconData get _formIcon {
    switch (medicine.dosageForm) {
      case DosageForm.tablet:
        return Icons.medication_outlined;
      case DosageForm.capsule:
        return Icons.medication_liquid_outlined;
      case DosageForm.injection:
        return Icons.vaccines_outlined;
      case DosageForm.syrup:
        return Icons.local_drink_outlined;
      case DosageForm.drops:
        return Icons.water_drop_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPaused = medicine.status == MedicineStatus.paused;

    return Dismissible(
      key: ValueKey(medicine.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false; // we handle state removal via the controller ourselves
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withAlpha((0.15 * 255).round())),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(_formIcon,
                      color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              medicine.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isPaused)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Paused',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.orange),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${medicine.dosageForm.label} · ${medicine.mealTiming.label}',
                        style: TextStyle(
                            fontSize: 12.5, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 13,
                              color: medicine.isOutOfStock
                                  ? Colors.red
                                  : medicine.isLowStock
                                      ? Colors.orange
                                      : Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            medicine.isOutOfStock
                                ? 'Out of stock'
                                : '${medicine.quantityRemaining} left',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: medicine.isLowStock ||
                                      medicine.isOutOfStock
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: medicine.isOutOfStock
                                  ? Colors.red
                                  : medicine.isLowStock
                                      ? Colors.orange
                                      : Colors.grey[500],
                            ),
                          ),
                          if (medicine.endDate != null) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.event_outlined,
                                size: 13, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              'until ${DateFormat('MMM d').format(medicine.endDate!)}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'pause_resume') onPauseResume();
                    if (value == 'archive') onArchive();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'pause_resume',
                      child: Text(isPaused ? 'Resume' : 'Pause'),
                    ),
                    const PopupMenuItem(
                      value: 'archive',
                      child: Text('Archive'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
