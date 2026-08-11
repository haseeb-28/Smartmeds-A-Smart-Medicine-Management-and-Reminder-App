import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import 'history_models.dart';

class HistoryRepository {
  final SupabaseClient _client = SupabaseService.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('No logged-in user');
    return id;
  }

  /// Applies date range / medicine / status filters server-side (cheap,
  /// indexed columns). Search-by-name is applied client-side afterward
  /// since it depends on the joined `medicines.name`, which keeps the
  /// query simple — fine at personal-app data volumes.
  Future<List<HistoryEntry>> fetchHistory(HistoryFilter filter) async {
    var query = _client
        .from('medicine_history')
        .select('*, medicines(name, dosage_form, meal_timing)')
        .eq('user_id', _userId);

    if (filter.dateRange != null) {
      query = query
          .gte('scheduled_time', filter.dateRange!.start.toIso8601String())
          .lt(
            'scheduled_time',
            filter.dateRange!.end
                .add(const Duration(days: 1))
                .toIso8601String(),
          );
    }
    if (filter.medicineId != null) {
      query = query.eq('medicine_id', filter.medicineId!);
    }
    if (filter.status != null) {
      query = query.eq('status', filter.status!.dbValue);
    }

    final response =
        await query.order('scheduled_time', ascending: false).limit(500);

    var entries = (response as List)
        .map((row) => HistoryEntry.fromJoinedJson(row as Map<String, dynamic>))
        .toList();

    if (filter.searchQuery.trim().isNotEmpty) {
      final q = filter.searchQuery.trim().toLowerCase();
      entries = entries
          .where((e) => e.medicineName.toLowerCase().contains(q))
          .toList();
    }

    return entries;
  }

  /// Distinct medicine id/name pairs that have history — powers the
  /// filter sheet's medicine dropdown without needing a second call to
  /// the medicines feature.
  Future<List<({String id, String name})>> fetchMedicinesWithHistory() async {
    final response = await _client
        .from('medicine_history')
        .select('medicine_id, medicines(name)')
        .eq('user_id', _userId);

    final seen = <String>{};
    final result = <({String id, String name})>[];
    for (final row in (response as List)) {
      final id = row['medicine_id'] as String;
      if (seen.contains(id)) continue;
      seen.add(id);
      final medicine = row['medicines'] as Map<String, dynamic>?;
      result.add((id: id, name: medicine?['name'] as String? ?? 'Medicine'));
    }
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }
}
