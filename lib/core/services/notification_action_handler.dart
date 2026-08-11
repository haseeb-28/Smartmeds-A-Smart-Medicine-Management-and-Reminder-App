import 'notification_service.dart';
import '../../features/medicines/data/medicine_repository.dart';
import '../../features/reminders/data/reminder_repository.dart';

/// This is the piece that closes the Module 4 → Module 5 gap: when the
/// user taps "Take Now" / "Skip" / "Snooze 10m" on a notification —
/// including from a killed/background app state — this handler updates
/// medicine_history directly. It intentionally does NOT go through
/// Riverpod providers, since there may be no live widget tree when a
/// notification action fires; it talks to Supabase directly via
/// ReminderRepository, same as the providers do under the hood.
class NotificationActionHandler {
  NotificationActionHandler._();

  static final _repository = ReminderRepository();
  static final _medicineRepository = MedicineRepository();

  /// Call once at app startup, before runApp().
  static void register() {
    NotificationService.instance.onActionTapped = _handle;
  }

  static Future<void> _handle(String payload, String actionId) async {
    final doseId = payload;
    if (doseId.isEmpty) return;

    switch (actionId) {
      case 'take_now':
        await _repository.markTaken(doseId);
        final dose = await _repository.fetchDoseById(doseId);
        if (dose != null) {
          await _medicineRepository.decrementStock(dose.medicineId, 1);
        }
        break;

      case 'skip':
        await _repository.markSkipped(doseId);
        break;

      case 'snooze_10':
        await _snooze(doseId);
        break;

      default:
        // Notification body tapped (no action button) — just opens the
        // app; nothing to update here. Dashboard will show current state.
        break;
    }
  }

  static Future<void> _snooze(String doseId) async {
    final dose = await _repository.fetchDoseById(doseId);
    if (dose == null) return;

    await NotificationService.instance.snoozeReminder(
      notificationId: NotificationService.idFromScheduleId(
        dose.scheduleId ?? doseId,
      ),
      medicineName: dose.medicineName,
      dosageLabel: dose.dosageLabel,
      payload: doseId,
    );
    // Dose stays "upcoming" — snoozing delays the reminder, it doesn't
    // change confirmation status. If the snoozed time also passes
    // unanswered, autoMarkOverdueMissed() in ReminderRepository will
    // eventually mark it missed on the next dashboard load.
  }
}
