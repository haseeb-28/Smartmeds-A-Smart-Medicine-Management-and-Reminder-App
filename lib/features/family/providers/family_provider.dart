import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/family_member_model.dart';
import '../data/family_repository.dart';

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepository();
});

class FamilyListController extends StateNotifier<AsyncValue<List<FamilyMember>>> {
  FamilyListController(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final FamilyRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      var members = await _repository.fetchAll();
      if (members.isEmpty) {
        // Brand-new user with no "Myself" row yet (registered after the
        // migration 005 backfill ran) — create it now rather than
        // showing an empty profile switcher on first launch.
        final self = await _repository.ensureSelfProfile();
        members = [self];
      }
      state = AsyncValue.data(members);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> addMember(FamilyMember member) async {
    try {
      final created = await _repository.addMember(member);
      state = state.whenData((list) => [...list, created]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateMember(FamilyMember member) async {
    try {
      final updated = await _repository.updateMember(member);
      state = state.whenData((list) => [
            for (final m in list)
              if (m.id == updated.id) updated else m,
          ]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteMember(String memberId) async {
    final previous = state;
    state = state.whenData(
        (list) => list.where((m) => m.id != memberId).toList());
    try {
      await _repository.deleteMember(memberId);
      return true;
    } catch (e) {
      state = previous;
      return false;
    }
  }
}

final familyListProvider =
    StateNotifierProvider<FamilyListController, AsyncValue<List<FamilyMember>>>(
        (ref) {
  return FamilyListController(ref.watch(familyRepositoryProvider));
});

/// The profile currently being viewed/managed across the whole app —
/// Dashboard, Medicines, Reminders, Prescriptions all read this to know
/// whose data to show. Defaults to null until family_members loads,
/// at which point the Dashboard sets it to the "Myself" profile.
final selectedProfileProvider = StateProvider<FamilyMember?>((ref) => null);
