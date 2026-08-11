import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/supabase_service.dart';
import 'prescription_model.dart';

class PrescriptionRepository {
  final SupabaseClient _client = SupabaseService.client;
  static const _bucket = 'prescriptions';

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('No logged-in user');
    return id;
  }

  Future<List<Prescription>> fetchAll({DocumentCategory? category}) async {
    var query = _client.from('prescriptions').select().eq('user_id', _userId);
    if (category != null) {
      query = query.eq('category', category.dbValue);
    }
    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((row) => Prescription.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Uploads [file] to the private `prescriptions` bucket under this
  /// user's folder (required by the RLS policy — see the SQL migration),
  /// then inserts the metadata row. Returns the created Prescription.
  Future<Prescription> upload({
    required File file,
    required String title,
    required DocumentCategory category,
    String? notes,
  }) async {
    final ext = file.path.split('.').last;
    final objectPath = '$_userId/${const Uuid().v4()}.$ext';

    await _client.storage.from(_bucket).upload(objectPath, file);

    final prescription = Prescription(
      id: '',
      userId: _userId,
      title: title,
      category: category,
      filePath: objectPath,
      notes: notes,
      createdAt: DateTime.now(),
    );

    final response = await _client
        .from('prescriptions')
        .insert(prescription.toInsertJson(_userId))
        .select()
        .single();
    return Prescription.fromJson(response);
  }

  Future<void> delete(Prescription prescription) async {
    await _client.storage.from(_bucket).remove([prescription.filePath]);
    await _client.from('prescriptions').delete().eq('id', prescription.id);
  }

  /// Bucket is private, so viewing a file needs a short-lived signed URL
  /// rather than a permanent public one — regenerated each time it's
  /// needed rather than stored, since it expires.
  Future<String> getSignedUrl(String filePath, {int expiresInSeconds = 3600}) {
    return _client.storage.from(_bucket).createSignedUrl(filePath, expiresInSeconds);
  }
}
