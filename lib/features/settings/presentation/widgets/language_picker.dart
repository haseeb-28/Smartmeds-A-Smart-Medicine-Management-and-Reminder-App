// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../data/settings_models.dart';

Future<AppLanguage?> showLanguagePicker(BuildContext context, AppLanguage current) {
  return showDialog<AppLanguage>(
    context: context,
      builder: (context) => SimpleDialog(
      title: const Text('Language'),
      children: [
        for (final language in AppLanguage.values)
          RadioListTile<AppLanguage>(
            title: Row(
              children: [
                Text(language.label),
                if (!language.isAvailable) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha((0.2 * 255).round()),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Coming soon', style: TextStyle(fontSize: 10)),
                  ),
                ],
              ],
            ),
            value: language,
            groupValue: current,
            onChanged: language.isAvailable
                ? (value) => Navigator.of(context).pop(value)
                : null,
          ),
      ],
    ),
  );
}
