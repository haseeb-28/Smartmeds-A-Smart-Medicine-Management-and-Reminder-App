import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/history_models.dart';
import '../data/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository();
});

class HistoryFilterController extends StateNotifier<HistoryFilter> {
  HistoryFilterController() : super(const HistoryFilter());

  void setSearchQuery(String query) => state = state.copyWith(searchQuery: query);
  void setDateRange(DateTimeRange? range) => range == null
      ? state = state.copyWith(clearDateRange: true)
      : state = state.copyWith(dateRange: range);
  void setMedicine(String? medicineId) => medicineId == null
      ? state = state.copyWith(clearMedicineId: true)
      : state = state.copyWith(medicineId: medicineId);
  void setStatus(HistoryStatus? status) => status == null
      ? state = state.copyWith(clearStatus: true)
      : state = state.copyWith(status: status);

  void clearAll() => state = const HistoryFilter();
}

final historyFilterProvider =
    StateNotifierProvider<HistoryFilterController, HistoryFilter>((ref) {
  return HistoryFilterController();
});

final filteredHistoryProvider = FutureProvider<List<HistoryEntry>>((ref) {
  final filter = ref.watch(historyFilterProvider);
  return ref.watch(historyRepositoryProvider).fetchHistory(filter);
});

final historyMedicineOptionsProvider =
    FutureProvider<List<({String id, String name})>>((ref) {
  return ref.watch(historyRepositoryProvider).fetchMedicinesWithHistory();
});
