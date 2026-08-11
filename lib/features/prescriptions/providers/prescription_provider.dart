import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/prescription_model.dart';
import '../data/prescription_repository.dart';

final prescriptionRepositoryProvider = Provider<PrescriptionRepository>((ref) {
  return PrescriptionRepository();
});

/// null = "All" category selected.
final prescriptionCategoryFilterProvider =
    StateProvider<DocumentCategory?>((ref) => null);

final prescriptionListProvider = FutureProvider<List<Prescription>>((ref) {
  final category = ref.watch(prescriptionCategoryFilterProvider);
  return ref.watch(prescriptionRepositoryProvider).fetchAll(category: category);
});

/// Signed URL for a single file — cached per filePath for the lifetime
/// of this provider instance so a list of thumbnails doesn't re-request
/// a fresh signed URL on every rebuild.
final signedUrlProvider =
    FutureProvider.family<String, String>((ref, filePath) {
  return ref.watch(prescriptionRepositoryProvider).getSignedUrl(filePath);
});

class UploadController extends StateNotifier<AsyncValue<void>> {
  UploadController(this._repository) : super(const AsyncValue.data(null));

  final PrescriptionRepository _repository;

  Future<bool> upload({
    required File file,
    required String title,
    required DocumentCategory category,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.upload(
        file: file,
        title: title,
        category: category,
        notes: notes,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final uploadControllerProvider =
    StateNotifierProvider<UploadController, AsyncValue<void>>((ref) {
  return UploadController(ref.watch(prescriptionRepositoryProvider));
});
