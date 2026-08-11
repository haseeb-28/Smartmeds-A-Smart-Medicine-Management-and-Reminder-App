import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import 'progress_models.dart';

class ProgressRepository {
  final SupabaseClient _client = SupabaseService.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('No logged-in user');
    return id;
  }

  Future<List<Map<String, dynamic>>> _fetchHistoryBetween(
      DateTime start, DateTime end) async {
    final response = await _client
        .from('medicine_history')
        .select('status, scheduled_time')
        .eq('user_id', _userId)
        .gte('scheduled_time', start.toIso8601String())
        .lt('scheduled_time', end.toIso8601String());
    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Module 6: today's Morning/Afternoon/Evening/Night breakdown +
  /// overall completion %, shown as check/cross rows on the Daily
  /// Progress screen.
  Future<DailyProgressBreakdown> fetchDailyBreakdown([DateTime? day]) async {
    final target = day ?? DateTime.now();
    final start = DateTime(target.year, target.month, target.day);
    final end = start.add(const Duration(days: 1));

    final rows = await _fetchHistoryBetween(start, end);

    final bySlot = <TimeSlot, List<String>>{
      for (final slot in TimeSlot.values) slot: [],
    };
    for (final row in rows) {
      final time = DateTime.parse(row['scheduled_time'] as String);
      final slot = TimeSlotX.fromHour(time.hour);
      bySlot[slot]!.add(row['status'] as String);
    }

    final slots = TimeSlot.values.map((slot) {
      final statuses = bySlot[slot]!;
      SlotOutcome outcome;
      if (statuses.isEmpty) {
        outcome = SlotOutcome.empty;
      } else if (statuses.every((s) => s == 'taken')) {
        outcome = SlotOutcome.taken;
      } else if (statuses.any((s) => s == 'missed')) {
        outcome = SlotOutcome.missed;
      } else if (statuses.any((s) => s == 'skipped')) {
        outcome = SlotOutcome.skipped;
      } else {
        outcome = SlotOutcome.upcoming;
      }
      return SlotSummary(
        slot: slot,
        outcome: outcome,
        doseCount: statuses.length,
      );
    }).toList();

    final takenCount = rows.where((r) => r['status'] == 'taken').length;

    return DailyProgressBreakdown(
      date: start,
      slots: slots,
      takenCount: takenCount,
      totalCount: rows.length,
    );
  }

  /// Last 7 days, oldest first — one completion % per day.
  Future<List<ProgressPoint>> fetchWeeklyProgress() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final end = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1));

    final rows = await _fetchHistoryBetween(start, end);
    const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return List.generate(7, (i) {
      final day = start.add(Duration(days: i));
      final dayRows = rows.where((r) {
        final t = DateTime.parse(r['scheduled_time'] as String);
        return t.year == day.year && t.month == day.month && t.day == day.day;
      }).toList();
      final taken = dayRows.where((r) => r['status'] == 'taken').length;
      final percent = dayRows.isEmpty ? 0.0 : taken / dayRows.length;
      return ProgressPoint(
        label: weekdayLabels[(day.weekday - 1) % 7],
        percent: percent,
      );
    });
  }

  /// Current calendar month, bucketed into weeks — a handful of bars
  /// rather than ~30 daily points, which reads better on a small chart.
  Future<List<ProgressPoint>> fetchMonthlyProgress() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    final rows = await _fetchHistoryBetween(monthStart, monthEnd);

    final weekCount = ((monthEnd.difference(monthStart).inDays) / 7).ceil();
    return List.generate(weekCount, (i) {
      final weekStart = monthStart.add(Duration(days: i * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final weekRows = rows.where((r) {
        final t = DateTime.parse(r['scheduled_time'] as String);
        return !t.isBefore(weekStart) && t.isBefore(weekEnd);
      }).toList();
      final taken = weekRows.where((r) => r['status'] == 'taken').length;
      final percent = weekRows.isEmpty ? 0.0 : taken / weekRows.length;
      return ProgressPoint(label: 'W${i + 1}', percent: percent);
    });
  }
}
