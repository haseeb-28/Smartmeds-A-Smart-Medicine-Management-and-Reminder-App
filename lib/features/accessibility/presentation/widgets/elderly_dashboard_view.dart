import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../dashboard/data/dashboard_models.dart';

/// Module 13's "Simple Navigation" / "Minimal Interface": strips the
/// Dashboard down to exactly what an elderly user needs to act on right
/// now — no calendar strip, no stats row, no secondary sections. Just
/// "what do I need to take, and two big buttons to respond." Everything
/// else (Progress, History, Calendar, Stock, Prescriptions, Family) is
/// still reachable through the same overflow menu — Elderly Mode
/// simplifies the primary screen, it doesn't remove functionality.
class ElderlyDashboardView extends StatelessWidget {
  final String userName;
  final List<UpcomingDose> doses;
  final void Function(String doseId) onTake;
  final void Function(String doseId) onSkip;

  const ElderlyDashboardView({
    super.key,
    required this.userName,
    required this.doses,
    required this.onTake,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final pending = doses.where((d) => d.status == DoseStatus.upcoming).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Hello, $userName',
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        if (pending.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha((0.12 * 255).round()),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 40),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'All done for now!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          )
        else
          for (final dose in pending) _BigDoseCard(
              dose: dose, onTake: () => onTake(dose.id), onSkip: () => onSkip(dose.id)),
      ],
    );
  }
}

class _BigDoseCard extends StatelessWidget {
  final UpcomingDose dose;
  final VoidCallback onTake;
  final VoidCallback onSkip;

  const _BigDoseCard({
    required this.dose,
    required this.onTake,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dose.medicineName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            '${dose.dosageLabel} • ${DateFormat('h:mm a').format(dose.time)}',
            style: const TextStyle(fontSize: 18, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSkip,
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: onTake,
                  child: const Text('Take Now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
