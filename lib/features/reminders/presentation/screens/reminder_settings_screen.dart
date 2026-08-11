import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/reminder_model.dart';
import '../../providers/reminder_provider.dart';
import '../widgets/schedule_time_tile.dart';
import '../widgets/time_preset_chips.dart';

class ReminderSettingsScreen extends ConsumerWidget {
  final String medicineId;
  final String medicineName;

  const ReminderSettingsScreen({
    super.key,
    required this.medicineId,
    required this.medicineName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(medicineScheduleProvider(medicineId));
    final controller = ref.watch(
      scheduleControllerProvider(
        (medicineId: medicineId, medicineName: medicineName),
      ).notifier,
    );

    Future<void> addTime(String label, TimeOfDay time) async {
      final schedule = MedicineSchedule(
        id: '',
        medicineId: medicineId,
        userId: '',
        timeOfDay: time,
        label: label,
      );
      await controller.addTime(schedule);
      ref.invalidate(medicineScheduleProvider(medicineId));
    }

    Future<void> pickCustomTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (picked != null) {
        await addTime('Custom', picked);
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('$medicineName — Reminders')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add a reminder time',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              TimePresetChips(
                onPresetSelected: addTime,
                onCustomSelected: pickCustomTime,
              ),
              const SizedBox(height: 24),
              Text(
                'Scheduled times',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: scheduleAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) =>
                      const Center(child: Text('Could not load reminders.')),
                  data: (schedules) {
                    if (schedules.isEmpty) {
                      return Center(
                        child: Text(
                          'No reminder times yet.\nAdd one above.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      );
                    }
                    return ListView(
                      children: [
                        for (final schedule in schedules)
                          ScheduleTimeTile(
                            schedule: schedule,
                            onDelete: () async {
                              await controller.removeTime(schedule.id);
                              ref.invalidate(
                                  medicineScheduleProvider(medicineId));
                            },
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
