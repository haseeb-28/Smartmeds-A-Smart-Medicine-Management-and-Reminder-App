// ignore_for_file: unused_element

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/local_cache_service.dart';
import '../../family/providers/family_provider.dart';
import '../data/medicine_model.dart';
import '../data/medicine_repository.dart';

final medicineRepositoryProvider = Provider<MedicineRepository>((ref) {
  return MedicineRepository();
});

enum MedicineLoadStatus { loading, loaded, error }

class MedicineListState {
  final MedicineLoadStatus status;
  final List<Medicine> medicines;
  final String? errorMessage;
  final bool isOffline;

  const MedicineListState({
    this.status = MedicineLoadStatus.loading,
    this.medicines = const [],
    this.errorMessage,
    this.isOffline = false,
  });

  List<Medicine> get active =>
      medicines.where((m) => m.status == MedicineStatus.active).toList();
  List<Medicine> get paused =>
      medicines.where((m) => m.status == MedicineStatus.paused).toList();

  MedicineListState copyWith({
    MedicineLoadStatus? status,
    List<Medicine>? medicines,
    String? errorMessage,
    bool? isOffline,
  }) {
    return MedicineListState(
      status: status ?? this.status,
      medicines: medicines ?? this.medicines,
      errorMessage: errorMessage,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

/// Loads active + paused medicines for whichever profile is currently
/// selected (Module 11) — NOT a fixed per-account list anymore. Rebuilt
/// automatically whenever selectedProfileProvider changes, since it's
/// constructed via `ref.watch` in the provider below.
class MedicineListController extends StateNotifier<MedicineListState> {
  MedicineListController(this._repository, this._profileId)
      : super(const MedicineListState()) {
    loadMedicines();
  }

  void _init() {
    loadMedicines();
  }

  final MedicineRepository _repository;
  final String? _profileId;
  final _cache = LocalCacheService.instance;

  String get _cacheKey => 'medicines_${_profileId ?? 'none'}';

  Future<void> loadMedicines() async {
    if (_profileId == null) {
      state = state.copyWith(status: MedicineLoadStatus.loaded, medicines: []);
      return;
    }
    state = state.copyWith(status: MedicineLoadStatus.loading);
    try {
      final medicines = await _repository.fetchActiveAndPaused(_profileId);
      state = state.copyWith(
        status: MedicineLoadStatus.loaded,
        medicines: medicines,
        isOffline: false,
      );
      // Module 15: cache on every successful fetch so the list is still
      // viewable (read-only) the next time this fails while offline.
      await _cache.save(_cacheKey, medicines.map((m) => m.toCacheJson()).toList());
    } catch (e) {
      final cached = await _cache.load(_cacheKey);
      if (cached != null) {
        state = state.copyWith(
          status: MedicineLoadStatus.loaded,
          medicines: cached.map(Medicine.fromJson).toList(),
          isOffline: true,
        );
      } else {
        state = state.copyWith(
          status: MedicineLoadStatus.error,
          errorMessage: 'Could not load medicines. Pull down to retry.',
        );
      }
    }
  }

  Future<bool> addMedicine(Medicine medicine) async {
    try {
      final created = await _repository.addMedicine(medicine);
      state = state.copyWith(medicines: [created, ...state.medicines]);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add medicine.');
      return false;
    }
  }

  Future<bool> updateMedicine(Medicine medicine) async {
    try {
      final updated = await _repository.updateMedicine(medicine);
      state = state.copyWith(
        medicines: [
          for (final m in state.medicines)
            if (m.id == updated.id) updated else m,
        ],
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update medicine.');
      return false;
    }
  }

  Future<void> deleteMedicine(String id) async {
    final previous = state.medicines;
    state = state.copyWith(
      medicines: previous.where((m) => m.id != id).toList(),
    );
    try {
      await _repository.deleteMedicine(id);
    } catch (e) {
      state = state.copyWith(
        medicines: previous,
        errorMessage: 'Failed to delete medicine.',
      );
    }
  }

  Future<void> pauseMedicine(String id) async {
    await _repository.pauseMedicine(id);
    await loadMedicines();
  }

  Future<void> resumeMedicine(String id) async {
    await _repository.resumeMedicine(id);
    await loadMedicines();
  }

  Future<void> archiveMedicine(String id) async {
    final previous = state.medicines;
    state = state.copyWith(
      medicines: previous.where((m) => m.id != id).toList(),
    );
    try {
      await _repository.archiveMedicine(id);
    } catch (e) {
      state = state.copyWith(
        medicines: previous,
        errorMessage: 'Failed to archive medicine.',
      );
    }
  }
}

final medicineListProvider =
    StateNotifierProvider<MedicineListController, MedicineListState>((ref) {
  final profile = ref.watch(selectedProfileProvider);
  return MedicineListController(
    ref.watch(medicineRepositoryProvider),
    profile?.id,
  );
});

/// Archived medicines for the currently selected profile — loaded
/// separately/lazily since they're only viewed occasionally.
final archivedMedicinesProvider = FutureProvider<List<Medicine>>((ref) {
  final profile = ref.watch(selectedProfileProvider);
  if (profile == null) return Future.value([]);
  return ref.watch(medicineRepositoryProvider).fetchArchived(profile.id);
});
