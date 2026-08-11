import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/family_member_model.dart';
import '../../providers/family_provider.dart';
import '../screens/add_edit_family_member_screen.dart';
import 'profile_avatar.dart';

class ProfileSwitcher extends ConsumerWidget {
  const ProfileSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(familyListProvider);
    final selected = ref.watch(selectedProfileProvider);

    return familyAsync.when(
      loading: () => const SizedBox(height: 64),
      error: (_, __) => const SizedBox.shrink(),
      data: (members) {
        // First load: default the active profile to "Myself".
        if (selected == null && members.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedProfileProvider.notifier).state =
                members.firstWhere((m) => m.isSelf, orElse: () => members.first);
          });
        }

        return SizedBox(
          height: 78,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final member in members)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: _ProfileChip(
                    member: member,
                    isSelected: selected?.id == member.id,
                    onTap: () => ref.read(selectedProfileProvider.notifier).state =
                        member,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: _AddProfileChip(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddEditFamilyMemberScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileChip extends StatelessWidget {
  final FamilyMember member;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProfileChip({
    required this.member,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary, width: 2)
                  : null,
            ),
            child: ProfileAvatar(member: member, radius: 24),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Text(
              member.isSelf ? 'Myself' : member.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddProfileChip extends StatelessWidget {
  final VoidCallback onTap;

  const _AddProfileChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.withAlpha((0.15 * 255).round()),
            child: const Icon(Icons.add, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          const SizedBox(
            width: 60,
            child: Text('Add', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5)),
          ),
        ],
      ),
    );
  }
}
