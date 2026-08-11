import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum QueuedActionType { taken, skipped }

class QueuedDoseAction {
  final String doseId;
  final QueuedActionType type;
  final DateTime queuedAt;

  const QueuedDoseAction({
    required this.doseId,
    required this.type,
    required this.queuedAt,
  });

  Map<String, dynamic> toJson() => {
        'doseId': doseId,
        'type': type.name,
        'queuedAt': queuedAt.toIso8601String(),
      };

  factory QueuedDoseAction.fromJson(Map<String, dynamic> json) {
    return QueuedDoseAction(
      doseId: json['doseId'] as String,
      type: QueuedActionType.values.firstWhere((e) => e.name == json['type']),
      queuedAt: DateTime.parse(json['queuedAt'] as String),
    );
  }
}

/// Holds dose confirmations (Take Now / Skip) made while offline, so they
/// can be replayed against Supabase once connectivity returns. This is
/// the actual mechanism behind the PRD's "automatically sync when
/// internet returns" — scoped specifically to dose confirmations, since
/// that's the one write action a patient realistically needs mid-outage
/// (adding new medicines, uploading prescriptions, etc. can reasonably
/// wait until the connection is back and aren't queued).
class OfflineQueueService {
  OfflineQueueService._();
  static final OfflineQueueService instance = OfflineQueueService._();

  static const _key = 'offline_dose_action_queue';

  Future<List<QueuedDoseAction>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded
        .map((e) => QueuedDoseAction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> enqueue(QueuedDoseAction action) async {
    final current = await getAll();
    // A later action for the same dose replaces an earlier queued one
    // (e.g. user tapped Skip, then Take Now before reconnecting) —
    // only the last intent should be replayed, not both in sequence.
    final filtered = current.where((a) => a.doseId != action.doseId).toList();
    filtered.add(action);
    await _save(filtered);
  }

  Future<void> remove(String doseId) async {
    final current = await getAll();
    await _save(current.where((a) => a.doseId != doseId).toList());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> _save(List<QueuedDoseAction> actions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(actions.map((a) => a.toJson()).toList()),
    );
  }
}
