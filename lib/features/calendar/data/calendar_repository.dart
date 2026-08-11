import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import 'calendar_models.dart';

class CalendarRepository {
  final SupabaseClient _client = SupabaseService.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('No logged-in user');
    return id;
  }

  DayStatus _dominantStatus(List<String> statuses) {
    if (statuses.isEmpty) return DayStatus.empty;
    if (statuses.contains('missed')) return DayStatus.missed;
    if (statuses.every((s) => s == 'taken')) return DayStatus.taken;
    if (statuses.contains('skipped')) return DayStatus.skipped;
    return DayStatus.upcoming;
  }

  /// Every day in [month] (1st through last day) with a dominant status —
  /// this is what colors the calendar grid. Days with no doses at all
  /// (e.g. future dates, or before any medicine existed) are DayStatus.empty
  /// and render as plain/uncolored cells.
  Future<List<CalendarDay>> fetchMonthDays(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    final response = await _client
        .from('medicine_history')
        .select('status, scheduled_time')
        .eq('user_id', _userId)
        .gte('scheduled_time', start.toIso8601String())
        .lt('scheduled_time', end.toIso8601String());

    final rows = (response as List).cast<Map<String, dynamic>>();
    final byDay = <int, List<String>>{};
    for (final row in rows) {
      final date = DateTime.parse(row['scheduled_time'] as String);
      byDay.putIfAbsent(date.day, () => []).add(row['status'] as String);
    }

    final daysInMonth = end.subtract(const Duration(days: 1)).day;
    return List.generate(daysInMonth, (i) {
      final day = i + 1;
      final statuses = byDay[day] ?? [];
      return CalendarDay(
        date: DateTime(month.year, month.month, day),
        status: _dominantStatus(statuses),
        doseCount: statuses.length,
      );
    });
  }

  /// Full dose history for a single tapped day, most recent first —
  /// shown in the day detail sheet.
  Future<List<DayHistoryEntry>> fetchDayHistory(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final response = await _client
        .from('medicine_history')
        .select('*, medicines(name, dosage_form, meal_timing)')
        .eq('user_id', _userId)
        .gte('scheduled_time', start.toIso8601String())
        .lt('scheduled_time', end.toIso8601String())
        .order('scheduled_time', ascending: false);

    return (response as List).map((row) {
      final json = row as Map<String, dynamic>;
      final medicine = json['medicines'] as Map<String, dynamic>?;
      return DayHistoryEntry(
        id: json['id'] as String,
        medicineName: medicine?['name'] as String? ?? 'Medicine',
        dosageLabel: medicine != null
            ? '${medicine['dosage_form']} · ${medicine['meal_timing']}'
            : '',
        scheduledTime: DateTime.parse(json['scheduled_time'] as String),
        respondedTime: json['responded_time'] != null
            ? DateTime.parse(json['responded_time'] as String)
            : null,
        status: _statusFromDb(json['status'] as String),
      );
    }).toList();
  }

  DayStatus _statusFromDb(String value) {
    switch (value) {
      case 'taken':
        return DayStatus.taken;
      case 'missed':
        return DayStatus.missed;
      case 'skipped':
        return DayStatus.skipped;
      default:
        return DayStatus.upcoming;
    }
  }
}
