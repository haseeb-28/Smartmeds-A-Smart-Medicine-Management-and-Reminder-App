import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/medicine_provider.dart';
import '../widgets/medicine_card.dart';
import 'add_edit_medicine_screen.dart';
import 'medicine_detail_screen.dart';

class MedicineListScreen extends ConsumerWidget {
  const MedicineListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(medicineListProvider);
    final controller = ref.read(medicineListProvider.notifier);

    ref.listen(medicineListProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('My Medicines')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEditMedicineScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Medicine'),
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadMedicines,
        child: Builder(
          builder: (context) {
            if (state.status == MedicineLoadStatus.loading &&
                state.medicines.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.medicines.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 100),
                  Icon(Icons.medication_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No medicines yet',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap "Add Medicine" to set up your first reminder.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                if (state.active.isNotEmpty) ...[
                  _SectionLabel(text: 'Active (${state.active.length})'),
                  const SizedBox(height: 8),
                  for (final medicine in state.active)
                    MedicineCard(
                      medicine: medicine,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              MedicineDetailScreen(medicine: medicine),
                        ),
                      ),
                      onPauseResume: () =>
                          controller.pauseMedicine(medicine.id),
                      onArchive: () => controller.archiveMedicine(medicine.id),
                      onDelete: () => controller.deleteMedicine(medicine.id),
                    ),
                ],
                if (state.paused.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _SectionLabel(text: 'Paused (${state.paused.length})'),
                  const SizedBox(height: 8),
                  for (final medicine in state.paused)
                    MedicineCard(
                      medicine: medicine,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              MedicineDetailScreen(medicine: medicine),
                        ),
                      ),
                      onPauseResume: () =>
                          controller.resumeMedicine(medicine.id),
                      onArchive: () => controller.archiveMedicine(medicine.id),
                      onDelete: () => controller.deleteMedicine(medicine.id),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey[600],
        letterSpacing: 0.3,
      ),
    );
  }
}
