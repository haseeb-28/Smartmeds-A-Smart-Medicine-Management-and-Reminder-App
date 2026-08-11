enum DosageForm { tablet, capsule, injection, syrup, drops }

enum MealTiming { beforeMeal, afterMeal, withFood, anytime }

enum MedicineStatus { active, paused, archived }

extension DosageFormX on DosageForm {
  String get dbValue => name;
  String get label {
    switch (this) {
      case DosageForm.tablet:
        return 'Tablet';
      case DosageForm.capsule:
        return 'Capsule';
      case DosageForm.injection:
        return 'Injection';
      case DosageForm.syrup:
        return 'Syrup';
      case DosageForm.drops:
        return 'Drops';
    }
  }

  static DosageForm fromDb(String value) => DosageForm.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => DosageForm.tablet,
      );
}

extension MealTimingX on MealTiming {
  String get dbValue {
    switch (this) {
      case MealTiming.beforeMeal:
        return 'before_meal';
      case MealTiming.afterMeal:
        return 'after_meal';
      case MealTiming.withFood:
        return 'with_food';
      case MealTiming.anytime:
        return 'anytime';
    }
  }

  String get label {
    switch (this) {
      case MealTiming.beforeMeal:
        return 'Before Meal';
      case MealTiming.afterMeal:
        return 'After Meal';
      case MealTiming.withFood:
        return 'With Food';
      case MealTiming.anytime:
        return 'Anytime';
    }
  }

  static MealTiming fromDb(String value) => MealTiming.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => MealTiming.anytime,
      );
}

extension MedicineStatusX on MedicineStatus {
  String get dbValue => name;

  static MedicineStatus fromDb(String value) => MedicineStatus.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => MedicineStatus.active,
      );
}

class Medicine {
  final String id;
  final String userId;
  final String name;
  final String? brandName;
  final String? genericName;
  final DosageForm dosageForm;
  final MealTiming mealTiming;
  final int quantityTotal;
  final int quantityRemaining;
  final String? imageUrl;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final MedicineStatus status;

  const Medicine({
    required this.id,
    required this.userId,
    required this.name,
    this.brandName,
    this.genericName,
    required this.dosageForm,
    required this.mealTiming,
    required this.quantityTotal,
    required this.quantityRemaining,
    this.imageUrl,
    required this.startDate,
    this.endDate,
    this.notes,
    this.status = MedicineStatus.active,
  });

  bool get isLowStock => quantityRemaining <= 5 && quantityRemaining > 0;
  bool get isOutOfStock => quantityRemaining <= 0;

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      brandName: json['brand_name'] as String?,
      genericName: json['generic_name'] as String?,
      dosageForm: DosageFormX.fromDb(json['dosage_form'] as String),
      mealTiming: MealTimingX.fromDb(json['meal_timing'] as String),
      quantityTotal: json['quantity_total'] as int? ?? 0,
      quantityRemaining: json['quantity_remaining'] as int? ?? 0,
      imageUrl: json['image_url'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      notes: json['notes'] as String?,
      status: MedicineStatusX.fromDb(json['status'] as String? ?? 'active'),
    );
  }

  Map<String, dynamic> toInsertJson(String userId) {
    return {
      'user_id': userId,
      'name': name,
      'brand_name': brandName,
      'generic_name': genericName,
      'dosage_form': dosageForm.dbValue,
      'meal_timing': mealTiming.dbValue,
      'quantity_total': quantityTotal,
      'quantity_remaining': quantityRemaining,
      'image_url': imageUrl,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'notes': notes,
      'status': status.dbValue,
    };
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'brand_name': brandName,
      'generic_name': genericName,
      'dosage_form': dosageForm.dbValue,
      'meal_timing': mealTiming.dbValue,
      'quantity_total': quantityTotal,
      'quantity_remaining': quantityRemaining,
      'image_url': imageUrl,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'notes': notes,
      'status': status.dbValue,
    };
  }

  Medicine copyWith({

    String? name,
    String? brandName,
    String? genericName,
    DosageForm? dosageForm,
    MealTiming? mealTiming,
    int? quantityTotal,
    int? quantityRemaining,
    String? imageUrl,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    MedicineStatus? status,
  }) {
    return Medicine(
      id: id,
      userId: userId,
      name: name ?? this.name,
      brandName: brandName ?? this.brandName,
      genericName: genericName ?? this.genericName,
      dosageForm: dosageForm ?? this.dosageForm,
      mealTiming: mealTiming ?? this.mealTiming,
      quantityTotal: quantityTotal ?? this.quantityTotal,
      quantityRemaining: quantityRemaining ?? this.quantityRemaining,
      imageUrl: imageUrl ?? this.imageUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }
}
