import 'package:flutter/material.dart';
import '../../data/reminder_model.dart';

class ScheduleTimeTile extends StatelessWidget {
  final MedicineSchedule schedule;
  final VoidCallback onDelete;

  const ScheduleTimeTile({
    super.key,
    required this.schedule,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha((0.15 * 255).round())),
      ),
      child: Row(
        children: [
          const Icon(Icons.alarm, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.timeOfDay.format(context),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
                Text(
                  schedule.label,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
