import 'package:flutter/material.dart';
import '../../data/statistics_models.dart';

class PeriodSelector extends StatelessWidget {
  final StatsPeriod selected;
  final ValueChanged<StatsPeriod> onChanged;

  const PeriodSelector({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<StatsPeriod>(
      segments: StatsPeriod.values
          .map((p) => ButtonSegment(value: p, label: Text(p.label)))
          .toList(),
      selected: {selected},
      onSelectionChanged: (set) => onChanged(set.first),
    );
  }
}
