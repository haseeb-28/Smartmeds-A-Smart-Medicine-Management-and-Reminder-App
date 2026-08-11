import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A snapshot cache, not a real local database. Stores the last
/// successfully-fetched JSON for a given key so it can be shown while
/// offline — it is NOT kept in sync with the server automatically and
/// is only ever as fresh as the last time `save()` was called after a
/// successful online fetch. Good enough for "show what I last saw,"
/// not a substitute for the relational local DB (Drift/SQLite) the PRD's
/// tech stack section originally called for.
class LocalCacheService {
  LocalCacheService._();
  static final LocalCacheService instance = LocalCacheService._();

  static const _prefix = 'cache_';

  Future<void> save(String key, List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$key', jsonEncode(items));
    await prefs.setString(
      '$_prefix${key}_savedAt',
      DateTime.now().toIso8601String(),
    );
  }

  Future<List<Map<String, dynamic>>?> load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$key');
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as List;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<DateTime?> savedAt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix${key}_savedAt');
    return raw == null ? null : DateTime.parse(raw);
  }
}
