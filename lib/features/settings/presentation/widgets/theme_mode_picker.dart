// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../data/settings_models.dart';

Future<AppThemeMode?> showThemeModePicker(BuildContext context, AppThemeMode current) {
  return showDialog<AppThemeMode>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Dark Mode'),
      children: [
        for (final mode in AppThemeMode.values)
          RadioListTile<AppThemeMode>(
            title: Text(mode.label),
            value: mode,
            groupValue: current,
            onChanged: (value) => Navigator.of(context).pop(value),
          ),
      ],
    ),
  );
}
