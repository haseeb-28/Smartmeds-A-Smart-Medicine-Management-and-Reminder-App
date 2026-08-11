import 'package:flutter/material.dart' show DateTimeRange;

enum HistoryStatus { taken, missed, skipped, upcoming }

extension HistoryStatusX on HistoryStatus {
  String get dbValue => name;
  String get label {
    switch (this) {
      case HistoryStatus.taken:
        return 'Taken';
      case HistoryStatus.missed:
        return 'Missed';
      case HistoryStatus.skipped:
        return 'Skipped';
      case HistoryStatus.upcoming:
        return 'Upcoming';
    }
  }

  static HistoryStatus fromDb(String value) => HistoryStatus.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => HistoryStatus.upcoming,
      );
}

class HistoryEntry {
  final String id;
  final String medicineId;
  final String medicineName;
  final String dosageLabel;
  final DateTime scheduledTime;
  final DateTime? respondedTime;
  final HistoryStatus status;

  const HistoryEntry({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.dosageLabel,
    required this.scheduledTime,
    this.respondedTime,
    required this.status,
  });

  factory HistoryEntry.fromJoinedJson(Map<String, dynamic> json) {
    final medicine = json['medicines'] as Map<String, dynamic>?;
    return HistoryEntry(
      id: json['id'] as String,
      medicineId: json['medicine_id'] as String,
      medicineName: medicine?['name'] as String? ?? 'Medicine',
      dosageLabel: medicine != null
          ? '${medicine['dosage_form']} · ${medicine['meal_timing']}'
          : '',
      scheduledTime: DateTime.parse(json['scheduled_time'] as String),
      respondedTime: json['responded_time'] != null
          ? DateTime.parse(json['responded_time'] as String)
          : null,
      status: HistoryStatusX.fromDb(json['status'] as String),
    );
  }
}

/// Search text + date range + medicine + status — all optional/nullable
/// meaning "no filter applied" for that field.
class HistoryFilter {
  final String searchQuery;
  final DateTimeRange? dateRange;
  final String? medicineId;
  final HistoryStatus? status;

  const HistoryFilter({
    this.searchQuery = '',
    this.dateRange,
    this.medicineId,
    this.status,
  });

  bool get isDefault =>
      searchQuery.isEmpty &&
      dateRange == null &&
      medicineId == null &&
      status == null;

  int get activeCount =>
      (searchQuery.isNotEmpty ? 1 : 0) +
      (dateRange != null ? 1 : 0) +
      (medicineId != null ? 1 : 0) +
      (status != null ? 1 : 0);

  HistoryFilter copyWith({
    String? searchQuery,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    String? medicineId,
    bool clearMedicineId = false,
    HistoryStatus? status,
    bool clearStatus = false,
  }) {
    return HistoryFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      medicineId: clearMedicineId ? null : (medicineId ?? this.medicineId),
      status: clearStatus ? null : (status ?? this.status),
    );
  }
}
