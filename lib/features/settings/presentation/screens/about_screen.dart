import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Icon(Icons.medication_liquid,
                size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'SmartMeds',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Version 1.0.0', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            const Text(
              'SmartMeds is a personal medicine management companion — '
              'reminders, adherence tracking, stock management, prescription '
              'storage, and family profile support, built with Flutter and '
              'Supabase.',
            ),
            const SizedBox(height: 20),
            const _AboutRow(label: 'Platform', value: 'Flutter (Android/iOS)'),
            const _AboutRow(label: 'Backend', value: 'Supabase'),
            const _AboutRow(label: 'State management', value: 'Riverpod'),
            const _AboutRow(label: 'Architecture', value: 'Clean Architecture, feature-first'),
          ],
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;

  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
