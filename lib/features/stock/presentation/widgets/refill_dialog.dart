import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../medicines/data/medicine_model.dart';
import '../../providers/stock_provider.dart';

class RefillDialog extends ConsumerStatefulWidget {
  final Medicine medicine;

  const RefillDialog({super.key, required this.medicine});

  @override
  ConsumerState<RefillDialog> createState() => _RefillDialogState();
}

class _RefillDialogState extends ConsumerState<RefillDialog> {
  final _controller = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final added = int.tryParse(_controller.text.trim());
    if (added == null || added <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final success = await ref
        .read(refillControllerProvider.notifier)
        .refill(widget.medicine.id, added);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.medicine.name} refilled by $added')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refill failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Refill ${widget.medicine.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Currently ${widget.medicine.quantityRemaining} of '
            '${widget.medicine.quantityTotal} remaining.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Units to add',
              hintText: 'e.g. 30',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Refill'),
        ),
      ],
    );
  }
}
