import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/prescription_model.dart';
import '../../providers/prescription_provider.dart';

class PrescriptionCard extends ConsumerWidget {
  final Prescription prescription;
  final VoidCallback onTap;

  const PrescriptionCard({
    super.key,
    required this.prescription,
    required this.onTap,
  });

  IconData get _categoryIcon {
    switch (prescription.category) {
      case DocumentCategory.bloodTest:
        return Icons.bloodtype_outlined;
      case DocumentCategory.xray:
        return Icons.medical_information_outlined;
      case DocumentCategory.prescription:
        return Icons.receipt_long_outlined;
      case DocumentCategory.others:
        return Icons.description_outlined;
    }
  }

  bool get _isImage {
    final ext = prescription.filePath.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'heic', 'webp'].contains(ext);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(signedUrlProvider(prescription.filePath));

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withAlpha((0.15 * 255).round())),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.3,
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: _isImage
                    ? urlAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, __) => Icon(_categoryIcon, size: 36),
                        data: (url) => Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(_categoryIcon, size: 36),
                        ),
                      )
                    : Center(
                        child: Icon(_categoryIcon,
                            size: 36,
                            color: Theme.of(context).colorScheme.primary),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prescription.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM d, yyyy').format(prescription.createdAt),
                    style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
