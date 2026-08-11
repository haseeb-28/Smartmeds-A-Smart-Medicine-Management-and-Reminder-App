import 'package:flutter/material.dart';
import '../../data/progress_models.dart';

class TimeSlotRow extends StatelessWidget {
  final SlotSummary summary;

  const TimeSlotRow({super.key, required this.summary});

  ({IconData icon, Color color, String text}) get _visual {
    switch (summary.outcome) {
      case SlotOutcome.taken:
        return (icon: Icons.check_circle, color: Colors.green, text: 'Taken');
      case SlotOutcome.missed:
        return (icon: Icons.cancel, color: Colors.red, text: 'Missed');
      case SlotOutcome.skipped:
        return (icon: Icons.remove_circle, color: Colors.orange, text: 'Skipped');
      case SlotOutcome.upcoming:
        return (icon: Icons.schedule, color: Colors.blueGrey, text: 'Upcoming');
      case SlotOutcome.empty:
        return (
          icon: Icons.remove_circle_outline,
          color: Colors.grey,
          text: 'No dose'
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _visual;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withAlpha((0.15 * 255).round())),
      ),
      child: Row(
        children: [
          Icon(v.icon, color: v.color, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              summary.slot.label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          Text(
            v.text,
            style: TextStyle(color: v.color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
