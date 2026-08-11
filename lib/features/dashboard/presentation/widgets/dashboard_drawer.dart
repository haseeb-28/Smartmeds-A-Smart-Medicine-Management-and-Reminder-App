import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../accessibility/presentation/screens/accessibility_screen.dart';
import '../../../authentication/providers/auth_provider.dart';
import '../../../family/presentation/screens/family_list_screen.dart';
import '../../../history/presentation/screens/medicine_history_screen.dart';
import '../../../prescriptions/presentation/screens/prescription_list_screen.dart';
import '../../../progress/presentation/screens/daily_progress_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../statistics/presentation/screens/statistics_screen.dart';
import '../../../stock/presentation/screens/stock_screen.dart';

/// Module 16 closes out a UX debt flagged back in Module 14: the
/// Dashboard's overflow popup menu had grown to 7 items and was noted
/// then as "close to where a drawer would serve better." With Settings
/// added as the 8th destination, this converts that popup menu into a
/// proper Drawer — same destinations, more room to scale further
/// without another cramped-menu problem.
class DashboardDrawer extends ConsumerWidget {
  const DashboardDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userEmail = ref.watch(authRepositoryProvider).currentUser?.email ?? '';

    void navigateTo(Widget screen) {
      Navigator.of(context).pop(); // close the drawer first
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Image.asset(
                    'assets/logo/app_logo.png',
                    height: 72,
                    errorBuilder: (_, __, ___) => Icon(Icons.medication_liquid,
                        size: 36, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 10),
                  Text(userEmail, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.insights_outlined),
                    title: const Text('Progress'),
                    onTap: () => navigateTo(const DailyProgressScreen()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.bar_chart_outlined),
                    title: const Text('Statistics'),
                    onTap: () => navigateTo(const StatisticsScreen()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('History'),
                    onTap: () => navigateTo(const MedicineHistoryScreen()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: const Text('Stock'),
                    onTap: () => navigateTo(const StockScreen()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.folder_open_outlined),
                    title: const Text('Prescriptions'),
                    onTap: () => navigateTo(const PrescriptionListScreen()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.family_restroom_outlined),
                    title: const Text('Family Profiles'),
                    onTap: () => navigateTo(const FamilyListScreen()),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.accessibility_new),
                    title: const Text('Accessibility'),
                    onTap: () => navigateTo(const AccessibilityScreen()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Settings'),
                    onTap: () => navigateTo(const SettingsScreen()),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.of(context).pop();
                await ref.read(authControllerProvider.notifier).logout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}