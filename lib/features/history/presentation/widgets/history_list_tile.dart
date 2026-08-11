import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/history_models.dart';

class HistoryListTile extends StatelessWidget {
  final HistoryEntry entry;

  const HistoryListTile({super.key, required this.entry});

  Color get _color {
    switch (entry.status) {
      case HistoryStatus.taken:
        return Colors.green;
      case HistoryStatus.missed:
        return Colors.red;
      case HistoryStatus.skipped:
        return Colors.orange;
      case HistoryStatus.upcoming:
        return Colors.blueGrey;
    }
  }

  IconData get _icon {
    switch (entry.status) {
      case HistoryStatus.taken:
        return Icons.check_circle;
      case HistoryStatus.missed:
        return Icons.cancel;
      case HistoryStatus.skipped:
        return Icons.remove_circle;
      case HistoryStatus.upcoming:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withAlpha((0.15 * 255).round())),
      ),
      child: Row(
        children: [
          Icon(_icon, color: _color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.medicineName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  entry.dosageLabel,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('MMM d').format(entry.scheduledTime),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('h:mm a').format(entry.scheduledTime),
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
