import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/family_member_model.dart';
import '../../providers/family_provider.dart';
import '../widgets/profile_avatar.dart';
import 'add_edit_family_member_screen.dart';

class FamilyListScreen extends ConsumerWidget {
  const FamilyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(familyListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Family Profiles')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => const AddEditFamilyMemberScreen()),
          );
        },
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add Member'),
      ),
      body: familyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Could not load family profiles.')),
        data: (members) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
          children: [
            for (final member in members)
              _FamilyMemberTile(member: member),
          ],
        ),
      ),
    );
  }
}

class _FamilyMemberTile extends ConsumerWidget {
  final FamilyMember member;

  const _FamilyMemberTile({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha((0.15 * 255).round())),
      ),
      child: Row(
        children: [
          ProfileAvatar(member: member),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                Text(
                  member.isSelf ? 'Your profile' : member.relationship.dbValue,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AddEditFamilyMemberScreen(existingMember: member),
                ),
              );
            },
          ),
          if (!member.isSelf)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Remove ${member.name}?'),
                    content: Text(
                        'This will also delete all of ${member.name}\'s medicines, '
                        'reminders, history, and documents. This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  final currentSelected = ref.read(selectedProfileProvider);
                  await ref
                      .read(familyListProvider.notifier)
                      .deleteMember(member.id);
                  // If the deleted profile was the active one being viewed,
                  // fall back to "Myself" so the app isn't left pointing
                  // at a profile that no longer exists.
                  if (currentSelected?.id == member.id) {
                    final members = ref.read(familyListProvider).value ?? [];
                    final self = members.where((m) => m.isSelf).firstOrNull;
                    ref.read(selectedProfileProvider.notifier).state = self;
                  }
                }
              },
            ),
        ],
      ),
    );
  }
}
