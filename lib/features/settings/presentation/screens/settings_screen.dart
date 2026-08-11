// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/export_service.dart';
import '../../../family/providers/family_provider.dart';
import '../../../history/data/history_models.dart';
import '../../../history/data/history_repository.dart';
import '../../../medicines/providers/medicine_provider.dart';
import '../../../medicines/data/medicine_model.dart';
import '../../data/settings_models.dart';
import '../../providers/language_provider.dart';
import '../../providers/notification_prefs_provider.dart';
import '../../providers/theme_mode_provider.dart';
import '../widgets/language_picker.dart';
import '../widgets/settings_tile.dart';
import '../widgets/theme_mode_picker.dart';
import 'about_screen.dart';
import 'account_screen.dart';
import 'privacy_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isBackingUp = false;

  Future<void> _runBackup() async {
    final profile = ref.read(selectedProfileProvider);
    if (profile == null) return;

    setState(() => _isBackingUp = true);
    try {
      final medicines = ref.read(medicineListProvider).medicines;
      final history = await HistoryRepository().fetchHistory(const HistoryFilter());

      await ExportService.exportJsonBackup({
        'exportedAt': DateTime.now().toIso8601String(),
        'profile': profile.name,
        'medicines': medicines
            .map((m) => {
                  'name': m.name,
                  'dosageForm': m.dosageForm.label,
                  'mealTiming': m.mealTiming.label,
                  'quantityRemaining': m.quantityRemaining,
                  'quantityTotal': m.quantityTotal,
                })
            .toList(),
        'doseHistory': history
            .map((h) => {
                  'medicine': h.medicineName,
                  'scheduledTime': h.scheduledTime.toIso8601String(),
                  'status': h.status.label,
                })
            .toList(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final language = ref.watch(languageProvider);
    final notificationPrefs = ref.watch(notificationPrefsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SettingsSectionLabel(text: 'Appearance'),
            SettingsTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              subtitle: themeMode.label,
              onTap: () async {
                final picked = await showThemeModePicker(context, themeMode);
                if (picked != null) {
                  await ref.read(themeModeProvider.notifier).setMode(picked);
                }
              },
            ),
            SettingsTile(
              icon: Icons.language_outlined,
              title: 'Language',
              subtitle: language.label,
              onTap: () async {
                final picked = await showLanguagePicker(context, language);
                if (picked != null) {
                  await ref.read(languageProvider.notifier).setLanguage(picked);
                }
              },
            ),

            const SettingsSectionLabel(text: 'Notifications'),
            SettingsTile(
              icon: Icons.music_note_outlined,
              title: 'Notification Sound',
              subtitle: notificationPrefs.sound.label,
              onTap: () async {
                final picked = await showDialog<NotificationSoundOption>(
                  context: context,
                    builder: (context) => SimpleDialog(
                    title: const Text('Notification Sound'),
                    children: [
                      for (final option in NotificationSoundOption.values)
                        RadioListTile<NotificationSoundOption>(
                          title: Text(option.label),
                          value: option,
                          groupValue: notificationPrefs.sound,
                          onChanged: (v) => Navigator.of(context).pop(v),
                        ),
                    ],
                  ),
                );
                if (picked != null) {
                  await ref.read(notificationPrefsProvider.notifier).setSound(picked);
                }
              },
            ),
            SettingsTile(
              icon: Icons.volume_up_outlined,
              title: 'Reminder Volume',
              subtitle: '${(notificationPrefs.volume * 100).round()}%',
              trailing: SizedBox(
                width: 140,
                child: Slider(
                  value: notificationPrefs.volume,
                  onChanged: (v) =>
                      ref.read(notificationPrefsProvider.notifier).setVolume(v),
                ),
              ),
            ),

            const SettingsSectionLabel(text: 'Data'),
            SettingsTile(
              icon: Icons.backup_outlined,
              title: 'Backup',
              subtitle: 'Export your data as a JSON file',
              trailing: _isBackingUp
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _isBackingUp ? null : _runBackup,
            ),

            const SettingsSectionLabel(text: 'Account'),
            SettingsTile(
              icon: Icons.person_outline,
              title: 'Account',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AccountScreen()),
              ),
            ),
            SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyScreen()),
              ),
            ),

            const SettingsSectionLabel(text: 'About'),
            SettingsTile(
              icon: Icons.info_outline,
              title: 'About SmartMeds',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
