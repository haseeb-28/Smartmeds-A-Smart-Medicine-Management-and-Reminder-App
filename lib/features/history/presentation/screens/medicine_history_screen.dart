import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/export_service.dart';
import '../../providers/history_provider.dart';
import '../widgets/history_filter_sheet.dart';
import '../widgets/history_list_tile.dart';

class MedicineHistoryScreen extends ConsumerStatefulWidget {
  const MedicineHistoryScreen({super.key});

  @override
  ConsumerState<MedicineHistoryScreen> createState() =>
      _MedicineHistoryScreenState();
}

class _MedicineHistoryScreenState
    extends ConsumerState<MedicineHistoryScreen> {
  final _searchController = TextEditingController();
  bool _isExporting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _export(bool asPdf) async {
    final entries = ref.read(filteredHistoryProvider).value ?? [];
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to export with current filters.')),
      );
      return;
    }
    setState(() => _isExporting = true);
    try {
      if (asPdf) {
        await ExportService.exportToPdf(entries);
      } else {
        await ExportService.exportToCsv(entries);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(historyFilterProvider);
    final historyAsync = ref.watch(filteredHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine History'),
        actions: [
          PopupMenuButton<String>(
            enabled: !_isExporting,
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share),
            onSelected: (value) => _export(value == 'pdf'),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'csv', child: Text('Export as CSV')),
              const PopupMenuItem(value: 'pdf', child: Text('Export as PDF')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => ref
                          .read(historyFilterProvider.notifier)
                          .setSearchQuery(value),
                      decoration: InputDecoration(
                        hintText: 'Search by medicine name',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.filter_list),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20)),
                            ),
                            builder: (_) => const HistoryFilterSheet(),
                          );
                        },
                      ),
                      if (filter.activeCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${filter.activeCount}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: historyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) =>
                    const Center(child: Text('Could not load history.')),
                data: (entries) {
                  if (entries.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 80),
                        Icon(Icons.history, size: 56, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          filter.isDefault
                              ? 'No history yet'
                              : 'No results for these filters',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: entries.length,
                    itemBuilder: (context, index) =>
                        HistoryListTile(entry: entries[index]),
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
