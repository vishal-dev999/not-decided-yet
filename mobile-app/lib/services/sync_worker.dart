import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'storage_service.dart';
import 'sync_service.dart';

class SyncWorker {
  static StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription;
  static Timer? _pollingTimer;
  static bool _isSyncing = false;

  /// Holds the latest remote lots fetched from the backend. UI can listen to this!
  static final ValueNotifier<List<Map<String, dynamic>>> latestLotsNotifier =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  /// Starts listening for network restoration and launches polling
  static void initialize(ReNovaStorage storage) {
    dispose();

    // 1. Connectivity listener
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) async {
      final hasConnection = results.any(
        (r) =>
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.ethernet ||
            r == ConnectivityResult.vpn,
      );

      if (hasConnection) {
        await runFullSync(storage);
      }
    });

    // 2. Periodic poll every 20 seconds while the app is active
    _pollingTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      await refreshRemoteStatus(storage);
    });

    // Run immediately on start
    runFullSync(storage);
  }

  /// Runs both upload of offline lots and status check
  static Future<void> runFullSync(ReNovaStorage storage) async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      // 1. Upload any pending local lots
      await SyncService.syncPendingLots(storage: storage);

      // 2. Fetch latest backend statuses (BROADCASTED, LOCKED, etc.)
      await refreshRemoteStatus(storage);
    } finally {
      _isSyncing = false;
    }
  }

  /// Fire-and-forget sync helper after creating a lot
  static void triggerImmediate(ReNovaStorage storage) {
    runFullSync(storage);
  }

  /// Explicitly queries GET /api/v1/collectors/me/lots and updates the notifier
  static Future<List<Map<String, dynamic>>> refreshRemoteStatus(
    ReNovaStorage storage,
  ) async {
    final remoteLots = await SyncService.fetchCollectorLots(storage: storage);

    // Filter out terminal states so background ticks don't reintroduce cancelled lots
    final activeLots = remoteLots.where((lot) {
      final s = (lot['status'] ?? '').toString().toUpperCase();
      return s != 'CANCELLED' && s != 'WITHDRAWN' && s != 'ARCHIVED';
    }).toList();

    latestLotsNotifier.value = activeLots;
    return activeLots;
  }

  static void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }
}
