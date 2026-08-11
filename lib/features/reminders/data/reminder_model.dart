import 'package:flutter/material.dart' show TimeOfDay;

enum DoseStatus { upcoming, taken, missed, skipped }

extension DoseStatusX on DoseStatus {
  String get dbValue => name;

  static DoseStatus fromDb(String value) => DoseStatus.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => DoseStatus.upcoming,
      );
}

/// A single reminder time attached to a medicine (e.g. "8:00 AM — Morning").
class MedicineSchedule {
  final String id;
  final String medicineId;
  final String userId;
  final TimeOfDay timeOfDay;
  final String label; // Morning, Afternoon, Evening, Night, Custom
  final bool isActive;

  const MedicineSchedule({
    required this.id,
    required this.medicineId,
    required this.userId,
    required this.timeOfDay,
    required this.label,
    this.isActive = true,
  });

  factory MedicineSchedule.fromJson(Map<String, dynamic> json) {
    final timeParts = (json['time_of_day'] as String).split(':');
    return MedicineSchedule(
      id: json['id'] as String,
      medicineId: json['medicine_id'] as String,
      userId: json['user_id'] as String,
      timeOfDay: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      label: json['label'] as String? ?? 'Custom',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toInsertJson({
    required String medicineId,
    required String userId,
  }) {
    final hh = timeOfDay.hour.toString().padLeft(2, '0');
    final mm = timeOfDay.minute.toString().padLeft(2, '0');
    return {
      'medicine_id': medicineId,
      'user_id': userId,
      'time_of_day': '$hh:$mm:00',
      'label': label,
      'is_active': isActive,
    };
  }
}

/// A single dose event — created when a schedule fires, updated
/// when the user taps Take Now / Skip, or auto-marked Missed later.
class DoseLog {
  final String id;

  Map<String, dynamic> toCacheJson() {
    return {
      'id': id,
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'dosage_label': dosageLabel,
      'schedule_id': scheduleId,
      'scheduled_time': scheduledTime.toIso8601String(),
      'responded_time': respondedTime?.toIso8601String(),
      'status': status.dbValue,
    };
  }

  static DoseLog fromCacheJson(Map<String, dynamic> json) {
    return DoseLog(
      id: json['id'] as String,
      medicineId: json['medicine_id'] as String,
      medicineName: json['medicine_name'] as String? ?? 'Medicine',
      dosageLabel: json['dosage_label'] as String? ?? '',
      scheduleId: json['schedule_id'] as String?,
      scheduledTime: DateTime.parse(json['scheduled_time'] as String),
      respondedTime: json['responded_time'] != null
          ? DateTime.parse(json['responded_time'] as String)
          : null,
      status: DoseStatusX.fromDb(json['status'] as String),
    );
  }

  final String medicineId;
  final String medicineName;
  final String dosageLabel;
  final String? scheduleId;
  final DateTime scheduledTime;
  final DateTime? respondedTime;
  final DoseStatus status;

  const DoseLog({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.dosageLabel,
    this.scheduleId,
    required this.scheduledTime,
    this.respondedTime,
    required this.status,
  });

  factory DoseLog.fromJoinedJson(Map<String, dynamic> json) {
    final medicine = json['medicines'] as Map<String, dynamic>?;
    return DoseLog(
      id: json['id'] as String,
      medicineId: json['medicine_id'] as String,
      medicineName: medicine?['name'] as String? ?? 'Medicine',
      dosageLabel: medicine != null
          ? '${medicine['dosage_form']} · ${medicine['meal_timing']}'
          : '',
      scheduleId: json['schedule_id'] as String?,
      scheduledTime: DateTime.parse(json['scheduled_time'] as String),
      respondedTime: json['responded_time'] != null
          ? DateTime.parse(json['responded_time'] as String)
          : null,
      status: DoseStatusX.fromDb(json['status'] as String),
    );
  }
}
