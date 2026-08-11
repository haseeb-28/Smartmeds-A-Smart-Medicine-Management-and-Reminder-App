import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/supabase_service.dart';
import 'reminder_model.dart';

class ReminderRepository {
  final SupabaseClient _client = SupabaseService.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('No logged-in user');
    return id;
  }

  // ---------- Schedule (reminder times per medicine) ----------
  // Not filtered by profile directly — a schedule belongs to one
  // medicine, and that medicine already belongs to one profile, so
  // there's nothing to scope here beyond the medicineId already passed in.

  Future<List<MedicineSchedule>> fetchScheduleForMedicine(
      String medicineId) async {
    final response = await _client
        .from('medicine_schedule')
        .select()
        .eq('medicine_id', medicineId)
        .order('time_of_day', ascending: true);
    return (response as List)
        .map((row) => MedicineSchedule.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<MedicineSchedule> addScheduleTime(
      MedicineSchedule schedule, String medicineId) async {
    final response = await _client
        .from('medicine_schedule')
        .insert(schedule.toInsertJson(medicineId: medicineId, userId: _userId))
        .select()
        .single();
    return MedicineSchedule.fromJson(response);
  }

  Future<void> removeScheduleTime(String scheduleId) async {
    await _client.from('medicine_schedule').delete().eq('id', scheduleId);
  }

  Future<void> setScheduleActive(String scheduleId, bool isActive) async {
    await _client
        .from('medicine_schedule')
        .update({'is_active': isActive}).eq('id', scheduleId);
  }

  // ---------- Dose history / today's doses ----------
  // Everything below is scoped by [profileId] (Module 11) via an inner
  // join to `medicines`, since medicine_history doesn't carry its own
  // profile_id column — it inherits the profile through medicine_id.

  Future<List<DoseLog>> fetchTodayDoses(String profileId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await _client
        .from('medicine_history')
        .select('*, medicines!inner(name, dosage_form, meal_timing, profile_id)')
        .eq('user_id', _userId)
        .eq('medicines.profile_id', profileId)
        .gte('scheduled_time', startOfDay.toIso8601String())
        .lt('scheduled_time', endOfDay.toIso8601String())
        .order('scheduled_time', ascending: true);

    return (response as List)
        .map((row) => DoseLog.fromJoinedJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Creates a medicine_history row for a schedule firing today.
  Future<DoseLog> createDoseEntry({
    required String medicineId,
    String? scheduleId,
    required DateTime scheduledTime,
  }) async {
    final response = await _client
        .from('medicine_history')
        .insert({
          'medicine_id': medicineId,
          'schedule_id': scheduleId,
          'user_id': _userId,
          'scheduled_time': scheduledTime.toIso8601String(),
          'status': DoseStatus.upcoming.dbValue,
        })
        .select('*, medicines(name, dosage_form, meal_timing)')
        .single();
    return DoseLog.fromJoinedJson(response);
  }

  Future<void> markDose(String doseId, DoseStatus status) async {
    await _client.from('medicine_history').update({
      'status': status.dbValue,
      'responded_time': DateTime.now().toIso8601String(),
    }).eq('id', doseId);
  }

  /// Per-day dominant status for the last [days] days (today included),
  /// oldest first — powers the Dashboard's mini calendar strip.
  Future<List<({DateTime date, DoseStatus status})>> fetchWeekCalendar(
      String profileId, {int days = 7}) async {
    final since = DateTime.now().subtract(Duration(days: days - 1));
    final startOfRange = DateTime(since.year, since.month, since.day);

    final response = await _client
        .from('medicine_history')
        .select('status, scheduled_time, medicines!inner(profile_id)')
        .eq('user_id', _userId)
        .eq('medicines.profile_id', profileId)
        .gte('scheduled_time', startOfRange.toIso8601String());

    final rows = response as List;
    final byDay = <String, List<String>>{};
    for (final r in rows) {
      final date = DateTime.parse(r['scheduled_time'] as String);
      final key = '${date.year}-${date.month}-${date.day}';
      byDay.putIfAbsent(key, () => []).add(r['status'] as String);
    }

    return List.generate(days, (i) {
      final date = startOfRange.add(Duration(days: i));
      final key = '${date.year}-${date.month}-${date.day}';
      final statuses = byDay[key] ?? [];
      DoseStatus dominant;
      if (statuses.isEmpty) {
        dominant = DoseStatus.upcoming;
      } else if (statuses.contains('missed')) {
        dominant = DoseStatus.missed;
      } else if (statuses.every((s) => s == 'taken')) {
        dominant = DoseStatus.taken;
      } else if (statuses.contains('skipped')) {
        dominant = DoseStatus.skipped;
      } else {
        dominant = DoseStatus.upcoming;
      }
      return (date: date, status: dominant);
    });
  }

  // ---------- Module 5: Confirmation support ----------

  /// Ensures a medicine_history row exists today for every active
  /// schedule belonging to [profileId]'s medicines.
  ///
  /// NOTE: client-side generation works for a single-device MVP, but
  /// runs every time the app opens/refreshes. A Supabase Edge Function
  /// on a daily cron is still the right long-term fix so doses exist
  /// even if the user never opens the app that day (needed for
  /// caregiver alerts in Module 12).
  Future<void> generateTodayDoseEntries(String profileId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final existing = await _client
        .from('medicine_history')
        .select('schedule_id, medicines!inner(profile_id)')
        .eq('user_id', _userId)
        .eq('medicines.profile_id', profileId)
        .gte('scheduled_time', startOfDay.toIso8601String())
        .lt('scheduled_time', endOfDay.toIso8601String());
    final existingScheduleIds =
        (existing as List).map((r) => r['schedule_id'] as String?).toSet();

    final schedules = await _client
        .from('medicine_schedule')
        .select('id, medicine_id, time_of_day, medicines!inner(profile_id)')
        .eq('user_id', _userId)
        .eq('medicines.profile_id', profileId)
        .eq('is_active', true);

    for (final s in (schedules as List)) {
      final scheduleId = s['id'] as String;
      if (existingScheduleIds.contains(scheduleId)) continue;

      final timeParts = (s['time_of_day'] as String).split(':');
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      await createDoseEntry(
        medicineId: s['medicine_id'] as String,
        scheduleId: scheduleId,
        scheduledTime: scheduledTime,
      );
    }
  }

  /// Runs autoMarkOverdueMissed for every profile on this account, not
  /// just whichever one is currently selected on the Dashboard. This is
  /// what makes Module 12 (Caregiver Support) actually work: a caregiver
  /// looking at their own "Myself" profile still needs to be alerted if
  /// "Mother" misses a dose, even though Mother's profile isn't the one
  /// currently open. Called from TodayDosesController.load() so it runs
  /// on every dashboard refresh regardless of which profile is active.
  Future<void> checkMissedDosesAcrossAllProfiles({int graceMinutes = 30}) async {
    final profiles = await _client
        .from('family_members')
        .select('id')
        .eq('user_id', _userId);

    for (final row in (profiles as List)) {
      await autoMarkOverdueMissed(
        row['id'] as String,
        graceMinutes: graceMinutes,
      );
    }
  }

  /// Auto-marks any dose still "upcoming" more than [graceMinutes] past
  /// its scheduled time as "missed", scoped to [profileId]. Also fires
  /// Module 12's caregiver alert — but ONLY for family member profiles
  /// (is_self = false), not the account holder's own missed doses,
  /// since "caregiver alert" means telling the caregiver someone ELSE
  /// needs attention, not reminding yourself of your own miss.
  Future<void> autoMarkOverdueMissed(String profileId, {int graceMinutes = 30}) async {
    final cutoff = DateTime.now().subtract(Duration(minutes: graceMinutes));
    final overdue = await _client
        .from('medicine_history')
        .select(
          'id, scheduled_time, medicines!inner(name, profile_id, family_members!inner(name, is_self))',
        )
        .eq('user_id', _userId)
        .eq('medicines.profile_id', profileId)
        .eq('status', DoseStatus.upcoming.dbValue)
        .lt('scheduled_time', cutoff.toIso8601String());

    final rows = (overdue as List).cast<Map<String, dynamic>>();
    if (rows.isEmpty) return;

    for (final row in rows) {
      final medicine = row['medicines'] as Map<String, dynamic>?;
      final familyMember = medicine?['family_members'] as Map<String, dynamic>?;
      final isSelf = familyMember?['is_self'] as bool? ?? true;
      if (isSelf) continue; // no caregiver alert for your own dose

      final scheduledTime = DateTime.parse(row['scheduled_time'] as String);
      await NotificationService.instance.showCaregiverAlert(
        notificationId: NotificationService.idFromDoseId(row['id'] as String),
        patientName: familyMember?['name'] as String? ?? 'Family member',
        medicineName: medicine?['name'] as String? ?? 'medicine',
        timeLabel: DateFormat('h:mm a').format(scheduledTime),
      );
    }

    final ids = rows.map((r) => r['id'] as String).toList();
    await _client
        .from('medicine_history')
        .update({'status': DoseStatus.missed.dbValue})
        .inFilter('id', ids);
  }

  /// Fetches a single dose by id — used when a notification action
  /// (Take Now / Skip / Snooze) fires and only has the dose id as payload.
  /// Not profile-filtered since the id alone is already specific enough.
  Future<DoseLog?> fetchDoseById(String doseId) async {
    final response = await _client
        .from('medicine_history')
        .select('*, medicines(name, dosage_form, meal_timing)')
        .eq('id', doseId)
        .maybeSingle();
    if (response == null) return null;
    return DoseLog.fromJoinedJson(response);
  }

  Future<void> markTaken(String doseId) => markDose(doseId, DoseStatus.taken);
  Future<void> markSkipped(String doseId) =>
      markDose(doseId, DoseStatus.skipped);
  Future<void> markMissed(String doseId) =>
      markDose(doseId, DoseStatus.missed);

  /// Adherence stats over the last [days] days, scoped to [profileId] —
  /// powers the Dashboard's weekly adherence % and streak.
  Future<({double adherencePercent, int streak})> fetchAdherenceStats(
      String profileId, {int days = 7}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final response = await _client
        .from('medicine_history')
        .select('status, scheduled_time, medicines!inner(profile_id)')
        .eq('user_id', _userId)
        .eq('medicines.profile_id', profileId)
        .gte('scheduled_time', since.toIso8601String())
        .neq('status', DoseStatus.upcoming.dbValue);

    final rows = response as List;
    if (rows.isEmpty) return (adherencePercent: 0.0, streak: 0);

    final taken = rows.where((r) => r['status'] == 'taken').length;
    final adherence = taken / rows.length;

    final byDay = <String, List<String>>{};
    for (final r in rows) {
      final date = DateTime.parse(r['scheduled_time'] as String);
      final key = '${date.year}-${date.month}-${date.day}';
      byDay.putIfAbsent(key, () => []).add(r['status'] as String);
    }
    int streak = 0;
    for (int i = 0; i < days; i++) {
      final day = DateTime.now().subtract(Duration(days: i));
      final key = '${day.year}-${day.month}-${day.day}';
      final statuses = byDay[key];
      if (statuses == null || statuses.isEmpty) break;
      if (statuses.every((s) => s == 'taken')) {
        streak++;
      } else {
        break;
      }
    }

    return (adherencePercent: adherence, streak: streak);
  }
}
