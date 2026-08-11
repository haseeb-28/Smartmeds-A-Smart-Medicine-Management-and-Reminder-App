import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/connectivity_provider.dart';

/// Shown at the top of the Dashboard when offline, so the "last saved
/// data" nature of what's on screen (Module 15's cache fallback) is
/// visible rather than silently pretending everything is live.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final isOffline = isOnlineAsync.maybeWhen(
      data: (online) => !online,
      orElse: () => false,
    );

    if (!isOffline) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "You're offline — showing your last saved data. "
              "Taking or skipping a dose will sync once you're back online.",
              style: TextStyle(fontSize: 12.5, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
