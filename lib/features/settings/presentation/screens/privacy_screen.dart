import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Your data',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'SmartMeds stores your medicines, reminders, dose history, and '
              'uploaded documents in Supabase, secured with Row Level Security '
              'so only your account can read or write your data. Family '
              'member profiles you add are managed under your account — they '
              'are not separate logins with their own data access.',
            ),
            const SizedBox(height: 20),
            Text(
              'Prescriptions and documents',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Uploaded prescription photos and lab reports are stored in a '
              'private storage bucket and are never publicly accessible by '
              'URL — viewing a file generates a short-lived signed link that '
              'expires automatically.',
            ),
            const SizedBox(height: 20),
            Text(
              'Notifications',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Dose reminders are scheduled locally on your device. Caregiver '
              'and stock alerts are generated on-device when the app is open '
              'and sent as local notifications — this app does not currently '
              'operate a push-notification server.',
            ),
            const SizedBox(height: 24),
            Text(
              'This is placeholder policy text for a portfolio/demo project, '
              'not a legally reviewed privacy policy.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
