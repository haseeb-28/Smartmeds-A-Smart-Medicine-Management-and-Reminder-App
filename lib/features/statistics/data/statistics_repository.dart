import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import 'statistics_models.dart';

class StatisticsRepository {
  final SupabaseClient _client = SupabaseService.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('No logged-in user');
    return id;
  }

  Future<List<Map<String, dynamic>>> _fetchHistory(
      String profileId, int? sinceDays) async {
    var query = _client
        .from('medicine_history')
        .select('status, scheduled_time, responded_time, medicines!inner(profile_id)')
        .eq('user_id', _userId)
        .eq('medicines.profile_id', profileId)
        .neq('status', 'upcoming');

    if (sinceDays != null) {
      final since = DateTime.now().subtract(Duration(days: sinceDays));
      query = query.gte('scheduled_time', since.toIso8601String());
    }

    final response = await query;
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<StatusCounts> fetchStatusCounts(String profileId, StatsPeriod period) async {
    final rows = await _fetchHistory(profileId, period.days);
    return StatusCounts(
      taken: rows.where((r) => r['status'] == 'taken').length,
      missed: rows.where((r) => r['status'] == 'missed').length,
      skipped: rows.where((r) => r['status'] == 'skipped').length,
    );
  }

  /// Average minutes between scheduled and actual confirmation time,
  /// taken doses only. Positive = late, negative = early/on-time.
  Future<double> fetchAverageDelayMinutes(String profileId, StatsPeriod period) async {
    final rows = await _fetchHistory(profileId, period.days);
    final takenWithResponse = rows.where(
        (r) => r['status'] == 'taken' && r['responded_time'] != null);
    if (takenWithResponse.isEmpty) return 0;

    final delays = takenWithResponse.map((r) {
      final scheduled = DateTime.parse(r['scheduled_time'] as String);
      final responded = DateTime.parse(r['responded_time'] as String);
      return responded.difference(scheduled).inMinutes.toDouble();
    });

    return delays.reduce((a, b) => a + b) / delays.length;
  }

  /// Daily adherence % for the trailing [days] — feeds the line chart.
  Future<List<TrendPoint>> fetchTrend(String profileId, {int days = 30}) async {
    final rows = await _fetchHistory(profileId, days);
    final start = DateTime.now().subtract(Duration(days: days - 1));
    final startOfRange = DateTime(start.year, start.month, start.day);

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
      final taken = statuses.where((s) => s == 'taken').length;
      final percent = statuses.isEmpty ? 0.0 : taken / statuses.length;
      return TrendPoint(date: date, percent: percent);
    });
  }

  /// True longest-ever streak of consecutive fully-adherent days across
  /// ALL history — not capped to a recent window like the Dashboard's
  /// quick streak counter (Module 4/6), which only looks at the last 7
  /// days. This one scans every day that has any history at all.
  Future<int> fetchLongestStreakEver(String profileId) async {
    final rows = await _fetchHistory(profileId, null);
    if (rows.isEmpty) return 0;

    final byDay = <String, List<String>>{};
    for (final r in rows) {
      final date = DateTime.parse(r['scheduled_time'] as String);
      final key = '${date.year}-${date.month}-${date.day}';
      byDay.putIfAbsent(key, () => []).add(r['status'] as String);
    }

    final sortedDays = byDay.keys.toList()
      ..sort((a, b) {
        final da = _parseKey(a);
        final db = _parseKey(b);
        return da.compareTo(db);
      });

    int longest = 0;
    int current = 0;
    DateTime? previousDay;

    for (final key in sortedDays) {
      final day = _parseKey(key);
      final allTaken = byDay[key]!.every((s) => s == 'taken');

      final isConsecutive =
          previousDay != null && day.difference(previousDay).inDays == 1;

      if (allTaken) {
        current = isConsecutive ? current + 1 : 1;
        longest = current > longest ? current : longest;
      } else {
        current = 0;
      }
      previousDay = day;
    }

    return longest;
  }

  DateTime _parseKey(String key) {
    final parts = key.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  Future<StatisticsSummary> fetchSummary(String profileId, StatsPeriod period) async {
    final counts = await fetchStatusCounts(profileId, period);
    final avgDelay = await fetchAverageDelayMinutes(profileId, period);
    final longestStreak = await fetchLongestStreakEver(profileId);
    final trend = await fetchTrend(profileId, days: period.days ?? 30);

    return StatisticsSummary(
      counts: counts,
      averageDelayMinutes: avgDelay,
      longestStreak: longestStreak,
      trend: trend,
    );
  }
}
