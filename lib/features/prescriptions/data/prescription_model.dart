enum DocumentCategory { bloodTest, xray, prescription, others }

extension DocumentCategoryX on DocumentCategory {
  String get dbValue {
    switch (this) {
      case DocumentCategory.bloodTest:
        return 'blood_test';
      case DocumentCategory.xray:
        return 'xray';
      case DocumentCategory.prescription:
        return 'prescription';
      case DocumentCategory.others:
        return 'others';
    }
  }

  String get label {
    switch (this) {
      case DocumentCategory.bloodTest:
        return 'Blood Test';
      case DocumentCategory.xray:
        return 'X-Ray';
      case DocumentCategory.prescription:
        return 'Prescription';
      case DocumentCategory.others:
        return 'Others';
    }
  }

  static DocumentCategory fromDb(String value) =>
      DocumentCategory.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => DocumentCategory.others,
      );
}

class Prescription {
  final String id;
  final String userId;
  final String title;
  final DocumentCategory category;
  final String filePath; // storage object path, e.g. "userId/uuid.jpg"
  final String? notes;
  final DateTime createdAt;

  const Prescription({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.filePath,
    this.notes,
    required this.createdAt,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      category: DocumentCategoryX.fromDb(json['category'] as String),
      filePath: json['file_path'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson(String userId) {
    return {
      'user_id': userId,
      'title': title,
      'category': category.dbValue,
      'file_path': filePath,
      'notes': notes,
    };
  }
}
