import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/supabase_service.dart';
import 'medicine_model.dart';

class MedicineRepository {
  final SupabaseClient _client = SupabaseService.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('No logged-in user');
    return id;
  }

  /// Fetches all non-archived medicines for the current user,
  /// most recently created first.
  Future<List<Medicine>> fetchActiveAndPaused(String? profileId) async {
    final response = await _client
        .from('medicines')
        .select()
        .eq('user_id', _userId)
        .neq('status', MedicineStatus.archived.dbValue)
        .order('created_at', ascending: false);
    return (response as List)
        .map((row) => Medicine.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<Medicine>> fetchArchived(String id) async {
    final response = await _client
        .from('medicines')
        .select()
        .eq('user_id', _userId)
        .eq('status', MedicineStatus.archived.dbValue)
        .order('created_at', ascending: false);
    return (response as List)
        .map((row) => Medicine.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<Medicine> addMedicine(Medicine medicine) async {
    final response = await _client
        .from('medicines')
        .insert(medicine.toInsertJson(_userId))
        .select()
        .single();
    return Medicine.fromJson(response);
  }

  Future<Medicine> updateMedicine(Medicine medicine) async {
    final response = await _client
        .from('medicines')
        .update(medicine.toInsertJson(_userId))
        .eq('id', medicine.id)
        .select()
        .single();
    return Medicine.fromJson(response);
  }

  Future<void> deleteMedicine(String medicineId) async {
    await _client.from('medicines').delete().eq('id', medicineId);
  }

  Future<void> setStatus(String medicineId, MedicineStatus status) async {
    await _client
        .from('medicines')
        .update({'status': status.dbValue}).eq('id', medicineId);
  }

  Future<void> pauseMedicine(String medicineId) =>
      setStatus(medicineId, MedicineStatus.paused);

  Future<void> resumeMedicine(String medicineId) =>
      setStatus(medicineId, MedicineStatus.active);

  Future<void> archiveMedicine(String medicineId) =>
      setStatus(medicineId, MedicineStatus.archived);

  /// Decrements stock by [amount] — called when a dose is marked "Taken"
  /// (wired in Module 5). Also fires a stock alert notification the
  /// moment remaining stock crosses into low (≤5) or out-of-stock (0),
  /// so alerts happen automatically wherever stock changes rather than
  /// needing every call site to remember to check.
  Future<void> decrementStock(String medicineId, int amount) async {
    final row = await _client
        .from('medicines')
        .select('name, quantity_remaining')
        .eq('id', medicineId)
        .single();
    final current = row['quantity_remaining'] as int? ?? 0;
    final name = row['name'] as String? ?? 'Medicine';
    final updated = (current - amount).clamp(0, current);

    await _client
        .from('medicines')
        .update({'quantity_remaining': updated}).eq('id', medicineId);

    final wasAboveThreshold = current > 5;
    final nowLow = updated <= 5 && updated > 0;
    final nowOut = updated == 0 && current > 0;

    if (nowOut) {
      await NotificationService.instance.showStockAlert(
        notificationId: NotificationService.idFromMedicineId(medicineId),
        medicineName: name,
        isOutOfStock: true,
      );
    } else if (nowLow && wasAboveThreshold) {
      // Only alert on the transition into "low", not on every dose
      // taken while already low — avoids a notification every single day.
      await NotificationService.instance.showStockAlert(
        notificationId: NotificationService.idFromMedicineId(medicineId),
        medicineName: name,
        isOutOfStock: false,
      );
    }
  }

  /// Adds [addedUnits] to both total and remaining — used by the
  /// "Refill" action on the Stock screen (Module 9).
  Future<void> refillStock(String medicineId, int addedUnits) async {
    final row = await _client
        .from('medicines')
        .select('quantity_total, quantity_remaining')
        .eq('id', medicineId)
        .single();
    final total = (row['quantity_total'] as int? ?? 0) + addedUnits;
    final remaining = (row['quantity_remaining'] as int? ?? 0) + addedUnits;

    await _client.from('medicines').update({
      'quantity_total': total,
      'quantity_remaining': remaining,
    }).eq('id', medicineId);
  }
}
