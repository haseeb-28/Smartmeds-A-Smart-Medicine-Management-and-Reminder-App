import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/elderly_mode_provider.dart';
import '../../../../core/services/voice_feedback_service.dart';

class AccessibilityScreen extends ConsumerWidget {
  const AccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = ref.watch(elderlyModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Accessibility')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withAlpha((0.15 * 255).round())),
              ),
              child: Row(
                children: [
                  Icon(Icons.accessibility_new,
                      size: 32, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Elderly Mode',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Larger text, bigger buttons, higher contrast, '
                          'a simplified home screen, and spoken confirmations.',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isEnabled,
                    onChanged: (value) async {
                      await ref
                          .read(elderlyModeProvider.notifier)
                          .setEnabled(value);
                      if (value) {
                        await VoiceFeedbackService.instance
                            .speak('Elderly mode turned on');
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'What changes',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const _FeatureRow(
              icon: Icons.text_fields,
              title: 'Large Font',
              description: 'Text size increases across the whole app.',
            ),
            const _FeatureRow(
              icon: Icons.touch_app,
              title: 'Large Buttons',
              description: 'Bigger, easier-to-tap buttons everywhere.',
            ),
            const _FeatureRow(
              icon: Icons.contrast,
              title: 'High Contrast',
              description: 'Pure black text on white for better legibility.',
            ),
            const _FeatureRow(
              icon: Icons.dashboard_customize_outlined,
              title: 'Simple Navigation',
              description:
                  'The Home screen shows only today\'s medicines and two '
                  'big Take / Skip buttons — nothing else competing for attention.',
            ),
            const _FeatureRow(
              icon: Icons.record_voice_over,
              title: 'Voice Feedback',
              description:
                  'Confirmations are spoken aloud when you take or skip a dose.',
            ),
            const SizedBox(height: 20),
            Text(
              'Everything else — Progress, History, Calendar, Stock, '
              'Prescriptions, and Family Profiles — is still reachable from '
              'the menu on the Home screen either way. Elderly Mode simplifies '
              'the home screen; it doesn\'t remove any features.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.grey[700]),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(description,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
