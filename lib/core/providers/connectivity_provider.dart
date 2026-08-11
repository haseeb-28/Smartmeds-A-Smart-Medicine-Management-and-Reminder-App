import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';

/// Live online/offline status. Defaults to `true` (online) while the
/// first check is in flight, since the app shouldn't flash an offline
/// banner during normal, connected startup.
final isOnlineProvider = StreamProvider<bool>((ref) {
  return ConnectivityService.instance.onStatusChange;
});
