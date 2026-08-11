import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/prescription_model.dart';
import '../../providers/prescription_provider.dart';
import '../widgets/category_selector.dart';

class AddPrescriptionScreen extends ConsumerStatefulWidget {
  const AddPrescriptionScreen({super.key});

  @override
  ConsumerState<AddPrescriptionScreen> createState() =>
      _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends ConsumerState<AddPrescriptionScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  DocumentCategory _category = DocumentCategory.prescription;
  File? _selectedFile;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() => _selectedFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a photo first')),
      );
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give the document a title')),
      );
      return;
    }

    setState(() => _isUploading = true);
    final success = await ref.read(uploadControllerProvider.notifier).upload(
          file: _selectedFile!,
          title: _titleController.text.trim(),
          category: _category,
          notes:
              _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isUploading = false);

    if (success) {
      ref.invalidate(prescriptionListProvider);
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Document')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                builder: (_) => SafeArea(
                  child: Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.photo_camera_outlined),
                        title: const Text('Take Photo'),
                        onTap: () {
                          Navigator.of(context).pop();
                          _pickImage(ImageSource.camera);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.photo_library_outlined),
                        title: const Text('Choose from Gallery'),
                        onTap: () {
                          Navigator.of(context).pop();
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.withAlpha((0.3 * 255).round()),
                    style: BorderStyle.solid,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _selectedFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              size: 36, color: Colors.grey[500]),
                          const SizedBox(height: 8),
                          Text('Tap to add a photo',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      )
                    : Image.file(_selectedFile!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g. Dr. Ahmed — Follow-up prescription',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text('Category',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            CategorySelector(
              selected: _category,
              onChanged: (c) => setState(() => _category = c!),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'e.g. Ordered by Dr. Ahmed for annual checkup',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submit,
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Upload Document'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
