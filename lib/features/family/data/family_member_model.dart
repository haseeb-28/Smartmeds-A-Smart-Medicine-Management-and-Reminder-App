enum Relationship { myself, mother, father, grandfather, grandmother, child, other }

extension RelationshipX on Relationship {
  String get dbValue {
    switch (this) {
      case Relationship.myself:
        return 'Myself';
      case Relationship.mother:
        return 'Mother';
      case Relationship.father:
        return 'Father';
      case Relationship.grandfather:
        return 'Grandfather';
      case Relationship.grandmother:
        return 'Grandmother';
      case Relationship.child:
        return 'Child';
      case Relationship.other:
        return 'Other';
    }
  }

  static Relationship fromDb(String value) => Relationship.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => Relationship.other,
      );
}

class FamilyMember {
  final String id;
  final String userId;
  final String name;
  final Relationship relationship;
  final bool isSelf;

  const FamilyMember({
    required this.id,
    required this.userId,
    required this.name,
    required this.relationship,
    this.isSelf = false,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      relationship: RelationshipX.fromDb(json['relationship'] as String),
      isSelf: json['is_self'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toInsertJson(String userId) {
    return {
      'user_id': userId,
      'name': name,
      'relationship': relationship.dbValue,
      'is_self': isSelf,
    };
  }
}
