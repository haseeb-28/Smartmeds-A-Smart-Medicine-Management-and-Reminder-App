import 'package:flutter/material.dart';

class TimePresetChips extends StatelessWidget {
  final void Function(String label, TimeOfDay time) onPresetSelected;
  final VoidCallback onCustomSelected;

  const TimePresetChips({
    super.key,
    required this.onPresetSelected,
    required this.onCustomSelected,
  });

  static const _presets = <String, TimeOfDay>{
    'Morning': TimeOfDay(hour: 8, minute: 0),
    'Afternoon': TimeOfDay(hour: 14, minute: 0),
    'Evening': TimeOfDay(hour: 18, minute: 0),
    'Night': TimeOfDay(hour: 21, minute: 0),
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._presets.entries.map(
          (entry) => ActionChip(
            avatar: const Icon(Icons.add, size: 16),
            label: Text(entry.key),
            onPressed: () => onPresetSelected(entry.key, entry.value),
          ),
        ),
        ActionChip(
          avatar: const Icon(Icons.edit_calendar, size: 16),
          label: const Text('Custom'),
          onPressed: onCustomSelected,
        ),
      ],
    );
  }
}
