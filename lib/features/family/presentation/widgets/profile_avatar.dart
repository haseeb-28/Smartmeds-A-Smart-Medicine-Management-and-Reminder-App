import 'package:flutter/material.dart';
import '../../data/family_member_model.dart';

class ProfileAvatar extends StatelessWidget {
  final FamilyMember member;
  final double radius;
  final bool isSelected;

  const ProfileAvatar({
    super.key,
    required this.member,
    this.radius = 22,
    this.isSelected = false,
  });

  Color _colorFor(Relationship relationship) {
    switch (relationship) {
      case Relationship.myself:
        return Colors.teal;
      case Relationship.mother:
        return Colors.pink;
      case Relationship.father:
        return Colors.indigo;
      case Relationship.grandfather:
        return Colors.brown;
      case Relationship.grandmother:
        return Colors.purple;
      case Relationship.child:
        return Colors.orange;
      case Relationship.other:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(member.relationship);
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withAlpha((0.15 * 255).round()),
      child: Text(
        member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }
}
