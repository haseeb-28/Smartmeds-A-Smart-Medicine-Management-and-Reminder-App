import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/prescription_provider.dart';
import '../../data/prescription_model.dart';
import '../widgets/category_selector.dart';
import '../widgets/prescription_card.dart';
import 'add_prescription_screen.dart';
import 'prescription_detail_screen.dart';

class PrescriptionListScreen extends ConsumerWidget {
  const PrescriptionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(prescriptionCategoryFilterProvider);
    final prescriptionsAsync = ref.watch(prescriptionListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Prescriptions & Documents')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddPrescriptionScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Document'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: CategorySelector(
                  selected: selectedCategory,
                  includeAllOption: true,
                  onChanged: (category) => ref
                      .read(prescriptionCategoryFilterProvider.notifier)
                      .state = category,
                ),
              ),
            ),
            Expanded(
              child: prescriptionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) =>
                    const Center(child: Text('Could not load documents.')),
                data: (prescriptions) {
                  if (prescriptions.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 80),
                        Icon(Icons.folder_open_outlined,
                            size: 56, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          selectedCategory == null
                              ? 'No documents yet'
                              : 'No ${selectedCategory.label} documents yet',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap "Add Document" to upload a prescription, lab '
                          'report, or scan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: prescriptions.length,
                    itemBuilder: (context, index) {
                      final prescription = prescriptions[index];
                      return PrescriptionCard(
                        prescription: prescription,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PrescriptionDetailScreen(
                                  prescription: prescription),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
