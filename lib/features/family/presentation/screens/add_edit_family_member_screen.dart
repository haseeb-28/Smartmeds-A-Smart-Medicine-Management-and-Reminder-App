import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/family_member_model.dart';
import '../../providers/family_provider.dart';

class AddEditFamilyMemberScreen extends ConsumerStatefulWidget {
  final FamilyMember? existingMember;

  const AddEditFamilyMemberScreen({super.key, this.existingMember});

  bool get isEditing => existingMember != null;

  @override
  ConsumerState<AddEditFamilyMemberScreen> createState() =>
      _AddEditFamilyMemberScreenState();
}

class _AddEditFamilyMemberScreenState
    extends ConsumerState<AddEditFamilyMemberScreen> {
  late final TextEditingController _nameController;
  late Relationship _relationship;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existingMember?.name ?? '');
    _relationship = widget.existingMember?.relationship ?? Relationship.mother;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final controller = ref.read(familyListProvider.notifier);
    final member = FamilyMember(
      id: widget.existingMember?.id ?? '',
      userId: '',
      name: _nameController.text.trim(),
      relationship: _relationship,
      isSelf: widget.existingMember?.isSelf ?? false,
    );

    final success = widget.isEditing
        ? await controller.updateMember(member)
        : await controller.addMember(member);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelf = widget.existingMember?.isSelf ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Profile' : 'Add Family Member'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _nameController,
              enabled: !isSelf, // "Myself" name stays tied to the account
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'e.g. Mother, Ahmed, Grandma',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            if (!isSelf) ...[
              Text(
                'Relationship',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in Relationship.values.where((r) => r != Relationship.myself))
                    ChoiceChip(
                      label: Text(r.dbValue),
                      selected: _relationship == r,
                      onSelected: (_) => setState(() => _relationship = r),
                    ),
                ],
              ),
              const SizedBox(height: 28),
            ] else
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'This is your own profile and can\'t be renamed or deleted — '
                  'it\'s tied to your SmartMeds account.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(widget.isEditing ? 'Save Changes' : 'Add Member'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
