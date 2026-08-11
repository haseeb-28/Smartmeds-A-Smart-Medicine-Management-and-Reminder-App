import '../../features/medicines/data/medicine_repository.dart';
import '../../features/reminders/data/reminder_model.dart';
import '../../features/reminders/data/reminder_repository.dart';
import 'offline_queue_service.dart';

/// Replays dose confirmations queued while offline. Called two ways so
/// "automatically sync when internet returns" actually happens in both
/// realistic situations:
/// 1. Opportunistically at the start of every dashboard load (covers
///    "user reopens/refreshes the app after being offline")
/// 2. From a connectivity-stream listener set up once in main.dart
///    (covers "app stays open in the background and reconnects mid-session")
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final _queue = OfflineQueueService.instance;
  final _reminderRepository = ReminderRepository();
  final _medicineRepository = MedicineRepository();

  bool _isSyncing = false;

  Future<void> syncPendingActions() async {
    if (_isSyncing) return; // avoid overlapping syncs from both call sites
    _isSyncing = true;
    try {
      final pending = await _queue.getAll();
      if (pending.isEmpty) return;

      for (final action in pending) {
        try {
          final status = action.type == QueuedActionType.taken
              ? DoseStatus.taken
              : DoseStatus.skipped;
          await _reminderRepository.markDose(action.doseId, status);

          if (status == DoseStatus.taken) {
            final dose = await _reminderRepository.fetchDoseById(action.doseId);
            if (dose != null) {
              await _medicineRepository.decrementStock(dose.medicineId, 1);
            }
          }
          await _queue.remove(action.doseId);
        } catch (e) {
          // Leave this one queued and keep trying the rest — a single
          // failed sync (e.g. the dose was deleted server-side in the
          // meantime) shouldn't block syncing everything else.
          continue;
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
