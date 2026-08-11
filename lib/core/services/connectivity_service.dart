import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper around connectivity_plus. Note this reports whether the
/// device THINKS it has a network connection, not whether Supabase is
/// actually reachable — a captive portal or DNS issue could still show
/// "online" here. Good enough for deciding when to attempt a sync, not
/// a guarantee every online-labeled attempt will succeed.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Stream<bool> get onStatusChange => _connectivity.onConnectivityChanged
      .map((results) => !results.contains(ConnectivityResult.none));
}
