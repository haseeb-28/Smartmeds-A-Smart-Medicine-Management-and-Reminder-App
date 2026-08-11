import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import 'family_member_model.dart';

class FamilyRepository {
  final SupabaseClient _client = SupabaseService.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('No logged-in user');
    return id;
  }

  /// "Myself" first, then everyone else by name. The backfill migration
  /// (005) guarantees every existing user already has a "Myself" row;
  /// for brand-new users, ensureSelfProfile() creates one on first load.
  Future<List<FamilyMember>> fetchAll() async {
    final response = await _client
        .from('family_members')
        .select()
        .eq('user_id', _userId)
        .order('is_self', ascending: false)
        .order('name', ascending: true);
    return (response as List)
        .map((row) => FamilyMember.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Creates the "Myself" profile if one doesn't exist yet — covers
  /// users who registered after migration 005 ran, since the SQL
  /// backfill only covered accounts that existed at migration time.
  Future<FamilyMember> ensureSelfProfile() async {
    final existing = await _client
        .from('family_members')
        .select()
        .eq('user_id', _userId)
        .eq('is_self', true)
        .maybeSingle();
    if (existing != null) return FamilyMember.fromJson(existing);

    final created = await _client
        .from('family_members')
        .insert({
          'user_id': _userId,
          'name': 'Myself',
          'relationship': 'Myself',
          'is_self': true,
        })
        .select()
        .single();
    return FamilyMember.fromJson(created);
  }

  Future<FamilyMember> addMember(FamilyMember member) async {
    final response = await _client
        .from('family_members')
        .insert(member.toInsertJson(_userId))
        .select()
        .single();
    return FamilyMember.fromJson(response);
  }

  Future<FamilyMember> updateMember(FamilyMember member) async {
    final response = await _client
        .from('family_members')
        .update(member.toInsertJson(_userId))
        .eq('id', member.id)
        .select()
        .single();
    return FamilyMember.fromJson(response);
  }

  /// Deleting a profile cascades to that profile's medicines and
  /// prescriptions (see `on delete cascade` in the SQL migration) —
  /// the RLS policy additionally blocks deleting the "Myself" profile.
  Future<void> deleteMember(String memberId) async {
    await _client.from('family_members').delete().eq('id', memberId);
  }
}
