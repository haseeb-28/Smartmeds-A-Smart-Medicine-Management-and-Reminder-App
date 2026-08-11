import 'package:flutter/material.dart';
import '../../data/medicine_model.dart';

class DosageFormSelector extends StatelessWidget {
  final DosageForm selected;
  final ValueChanged<DosageForm> onChanged;

  const DosageFormSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DosageForm.values.map((form) {
        final isSelected = form == selected;
        return ChoiceChip(
          label: Text(form.label),
          selected: isSelected,
          onSelected: (_) => onChanged(form),
        );
      }).toList(),
    );
  }
}
