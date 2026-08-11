import 'package:flutter/material.dart';
import '../../data/prescription_model.dart';

class CategorySelector extends StatelessWidget {
  final DocumentCategory? selected;
  final bool includeAllOption;
  final ValueChanged<DocumentCategory?> onChanged;

  const CategorySelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.includeAllOption = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (includeAllOption)
          ChoiceChip(
            label: const Text('All'),
            selected: selected == null,
            onSelected: (_) => onChanged(null),
          ),
        for (final category in DocumentCategory.values)
          ChoiceChip(
            label: Text(category.label),
            selected: selected == category,
            onSelected: (_) => onChanged(category),
          ),
      ],
    );
  }
}
