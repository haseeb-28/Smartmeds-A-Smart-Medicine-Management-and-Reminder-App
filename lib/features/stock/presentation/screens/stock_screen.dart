import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../medicines/data/medicine_model.dart';
import '../../data/stock_models.dart';
import '../../providers/stock_provider.dart';
import '../widgets/refill_dialog.dart';
import '../widgets/stock_progress_bar.dart';

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicines = ref.watch(stockSortedMedicinesProvider);
    final lowOrOutCount = medicines
        .where((m) => StockLevelX.classify(m.quantityRemaining) != StockLevel.normal)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Medicine Stock')),
      body: SafeArea(
        child: medicines.isEmpty
            ? Center(
                child: Text(
                  'No medicines yet.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (lowOrOutCount > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.orange),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$lowOrOutCount medicine${lowOrOutCount > 1 ? 's' : ''} '
                              'need${lowOrOutCount == 1 ? 's' : ''} attention',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  for (final medicine in medicines)
                    _StockTile(medicine: medicine),
                ],
              ),
      ),
    );
  }
}

class _StockTile extends StatelessWidget {
  final Medicine medicine;

  const _StockTile({required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  medicine.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => RefillDialog(medicine: medicine),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Refill'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StockProgressBar(
            remaining: medicine.quantityRemaining,
            total: medicine.quantityTotal,
          ),
        ],
      ),
    );
  }
}
