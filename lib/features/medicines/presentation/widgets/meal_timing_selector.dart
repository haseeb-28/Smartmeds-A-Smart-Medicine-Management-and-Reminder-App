import 'package:flutter/material.dart';
import '../../data/medicine_model.dart';

class MealTimingSelector extends StatelessWidget {
  final MealTiming selected;
  final ValueChanged<MealTiming> onChanged;

  const MealTimingSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MealTiming.values.map((timing) {
        final isSelected = timing == selected;
        return ChoiceChip(
          label: Text(timing.label),
          selected: isSelected,
          onSelected: (_) => onChanged(timing),
        );
      }).toList(),
    );
  }
}
