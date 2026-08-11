import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../data/medicine_model.dart';
import '../../providers/medicine_provider.dart';
import '../widgets/dosage_form_selector.dart';
import '../widgets/meal_timing_selector.dart';

class AddEditMedicineScreen extends ConsumerStatefulWidget {
  final Medicine? existingMedicine;

  const AddEditMedicineScreen({super.key, this.existingMedicine});

  bool get isEditing => existingMedicine != null;

  @override
  ConsumerState<AddEditMedicineScreen> createState() =>
      _AddEditMedicineScreenState();
}

class _AddEditMedicineScreenState
    extends ConsumerState<AddEditMedicineScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _genericController;
  late final TextEditingController _quantityController;
  late final TextEditingController _notesController;

  late DosageForm _dosageForm;
  late MealTiming _mealTiming;
  late DateTime _startDate;
  DateTime? _endDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingMedicine;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _brandController = TextEditingController(text: existing?.brandName ?? '');
    _genericController =
        TextEditingController(text: existing?.genericName ?? '');
    _quantityController = TextEditingController(
      text: existing != null ? existing.quantityTotal.toString() : '',
    );
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _dosageForm = existing?.dosageForm ?? DosageForm.tablet;
    _mealTiming = existing?.mealTiming ?? MealTiming.anytime;
    _startDate = existing?.startDate ?? DateTime.now();
    _endDate = existing?.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _genericController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? _startDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    final userId = SupabaseService.auth.currentUser?.id ?? '';

    final medicine = Medicine(
      id: widget.existingMedicine?.id ?? '',
      userId: userId,
      name: _nameController.text.trim(),
      brandName: _brandController.text.trim().isEmpty
          ? null
          : _brandController.text.trim(),
      genericName: _genericController.text.trim().isEmpty
          ? null
          : _genericController.text.trim(),
      dosageForm: _dosageForm,
      mealTiming: _mealTiming,
      quantityTotal: quantity,
      quantityRemaining:
          widget.existingMedicine?.quantityRemaining ?? quantity,
      startDate: _startDate,
      endDate: _endDate,
      notes:
          _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      status: widget.existingMedicine?.status ?? MedicineStatus.active,
    );

    final controller = ref.read(medicineListProvider.notifier);
    final success = widget.isEditing
        ? await controller.updateMedicine(medicine)
        : await controller.addMedicine(medicine);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing
              ? 'Could not update medicine. Try again.'
              : 'Could not add medicine. Try again.'),
        ),
      );
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Medicine' : 'Add Medicine'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _brandController,
                      decoration: const InputDecoration(
                        labelText: 'Brand Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _genericController,
                      decoration: const InputDecoration(
                        labelText: 'Generic Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Dosage Form',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DosageFormSelector(
                selected: _dosageForm,
                onChanged: (v) => setState(() => _dosageForm = v),
              ),
              const SizedBox(height: 20),
              Text('Meal Timing',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              MealTimingSelector(
                selected: _mealTiming,
                onChanged: (v) => setState(() => _mealTiming = v),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity (e.g. 60 tablets) *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Quantity is required';
                  if (int.tryParse(v.trim()) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(isStart: true),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text('Start: ${_formatDate(_startDate)}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(isStart: false),
                      icon: const Icon(Icons.event_outlined, size: 16),
                      label: Text(_endDate == null
                          ? 'End: Ongoing'
                          : 'End: ${_formatDate(_endDate!)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'e.g. Take with a full glass of water',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(widget.isEditing ? 'Save Changes' : 'Add Medicine'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
