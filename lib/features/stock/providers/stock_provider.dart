import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../medicines/data/medicine_model.dart';
import '../../medicines/providers/medicine_provider.dart';

/// Deliberately no separate stock repository — Module 3's `medicines`
/// table already has quantity_total/quantity_remaining, and
/// MedicineRepository already has decrementStock() (Module 5) and
/// refillStock() (this module). Stock is a *view* over medicines data,
/// not a separate concern with its own table.

/// Active + paused medicines sorted lowest-stock-first, so anything
/// needing attention surfaces at the top of the Stock screen.
final stockSortedMedicinesProvider = Provider<List<Medicine>>((ref) {
  final state = ref.watch(medicineListProvider);
  final medicines = [...state.medicines];
  medicines.sort((a, b) => a.quantityRemaining.compareTo(b.quantityRemaining));
  return medicines;
});

class RefillController extends StateNotifier<AsyncValue<void>> {
  RefillController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<bool> refill(String medicineId, int addedUnits) async {
    state = const AsyncValue.loading();
    try {
      await _ref
          .read(medicineRepositoryProvider)
          .refillStock(medicineId, addedUnits);
      await _ref.read(medicineListProvider.notifier).loadMedicines();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final refillControllerProvider =
    StateNotifierProvider<RefillController, AsyncValue<void>>((ref) {
  return RefillController(ref);
});
