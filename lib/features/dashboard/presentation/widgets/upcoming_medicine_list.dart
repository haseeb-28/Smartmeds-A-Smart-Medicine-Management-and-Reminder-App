import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/dashboard_models.dart';

class UpcomingMedicineList extends StatelessWidget {
  final List<UpcomingDose> doses;
  final void Function(String doseId)? onTake;
  final void Function(String doseId)? onSkip;

  const UpcomingMedicineList({
    super.key,
    required this.doses,
    this.onTake,
    this.onSkip,
  });

  Color _statusColor(DoseStatus status) {
    switch (status) {
      case DoseStatus.taken:
        return Colors.green;
      case DoseStatus.missed:
        return Colors.red;
      case DoseStatus.skipped:
        return Colors.orange;
      case DoseStatus.upcoming:
        return Colors.blueGrey;
    }
  }

  IconData _statusIcon(DoseStatus status) {
    switch (status) {
      case DoseStatus.taken:
        return Icons.check_circle;
      case DoseStatus.missed:
        return Icons.cancel;
      case DoseStatus.skipped:
        return Icons.remove_circle;
      case DoseStatus.upcoming:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (doses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('No medicines scheduled for today.'),
      );
    }

    return Column(
      children: doses.map((dose) {
        final color = _statusColor(dose.status);
        final isPending = dose.status == DoseStatus.upcoming;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withAlpha((0.15 * 255).round())),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_statusIcon(dose.status), color: color, size: 26),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dose.medicineName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dose.dosageLabel,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('h:mm a').format(dose.time),
                    style: TextStyle(fontWeight: FontWeight.w600, color: color),
                  ),
                ],
              ),
              if (isPending && (onTake != null || onSkip != null)) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (onSkip != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => onSkip!(dose.id),
                          child: const Text('Skip'),
                        ),
                      ),
                    if (onSkip != null && onTake != null)
                      const SizedBox(width: 10),
                    if (onTake != null)
                      Expanded(
                        child: FilledButton(
                          onPressed: () => onTake!(dose.id),
                          child: const Text('Take Now'),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
