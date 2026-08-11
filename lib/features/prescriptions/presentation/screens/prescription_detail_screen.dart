import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/prescription_model.dart';
import '../../providers/prescription_provider.dart';

class PrescriptionDetailScreen extends ConsumerWidget {
  final Prescription prescription;

  const PrescriptionDetailScreen({super.key, required this.prescription});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(signedUrlProvider(prescription.filePath));

    return Scaffold(
      appBar: AppBar(
        title: Text(prescription.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Document?'),
                  content: const Text(
                      'This will permanently delete this file. This cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child:
                          const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref
                    .read(prescriptionRepositoryProvider)
                    .delete(prescription);
                ref.invalidate(prescriptionListProvider);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: urlAsync.when(
                loading: () => const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox(
                  height: 200,
                  child: Center(child: Text('Could not load file preview.')),
                ),
                data: (url) => InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 200,
                      child: Center(child: Text('Preview not available.')),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _DetailRow(label: 'Category', value: prescription.category.label),
            _DetailRow(
              label: 'Added',
              value: DateFormat('MMMM d, yyyy — h:mm a')
                  .format(prescription.createdAt),
            ),
            if (prescription.notes != null && prescription.notes!.isNotEmpty)
              _DetailRow(label: 'Notes', value: prescription.notes!),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
