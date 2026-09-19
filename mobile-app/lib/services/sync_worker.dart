import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'storage_service.dart';
import 'sync_service.dart';
import '../services/database_helper.dart';

class SyncWorker {
  static StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription;
  static Timer? _pollingTimer;
  static bool _isSyncing = false;

  /// In-memory cache for weighed lot transactions: backend lot_id -> transaction map
  /// Prevents spamming /status on every 20-second tick once scale values are known.
  static final Map<String, Map<String, dynamic>> _txnCache = {};

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

    final activeLots = remoteLots.where((lot) {
      final s = (lot['status'] ?? '').toString().toUpperCase();
      return s != 'CANCELLED' && s != 'WITHDRAWN' && s != 'ARCHIVED';
    }).toList();

    // Query SQLite queue to preserve local photo paths
    final localRows = await DatabaseHelper.instance.getQueuedLots(limit: 100);
    final Map<String, String> localImageMap = {};
    for (final row in localRows) {
      final img = (row['image_path'] ?? row['photo_path'] ?? '') as String;
      if (img.isNotEmpty) {
        final uid = (row['lot_uid'] ?? '').toString();
        final clientUid = (row['client_lot_id'] ?? '').toString();
        if (uid.isNotEmpty) localImageMap[uid] = img;
        if (clientUid.isNotEmpty) localImageMap[clientUid] = img;
      }
    }

    final enrichedLots = await Future.wait(
      activeLots.map((lot) async {
        final status = (lot['status'] ?? '').toString().toUpperCase();
        final backendId = (lot['id'] ?? '').toString();
        final clientUid = (lot['client_lot_id'] ?? '').toString();
        final lotUid = (lot['lot_uid'] ?? '').toString();

        final mutable = Map<String, dynamic>.from(lot);

        // Check all possible identifiers for the image path
        if (clientUid.isNotEmpty && localImageMap.containsKey(clientUid)) {
          mutable['image_path'] = localImageMap[clientUid];
        } else if (lotUid.isNotEmpty && localImageMap.containsKey(lotUid)) {
          mutable['image_path'] = localImageMap[lotUid];
        } else if (backendId.isNotEmpty &&
            localImageMap.containsKey(backendId)) {
          mutable['image_path'] = localImageMap[backendId];
        }

        if (status == 'WEIGHED' && backendId.isNotEmpty) {
          // Check in-memory cache first
          if (_txnCache.containsKey(backendId)) {
            mutable['transaction'] = _txnCache[backendId];
          } else {
            // Fetch once from backend, then store in cache
            final details = await SyncService.fetchLotStatus(
              storage: storage,
              lotId: backendId,
            );
            if (details != null && details['transaction'] != null) {
              final txn = details['transaction'] as Map<String, dynamic>;
              _txnCache[backendId] = txn;
              mutable['transaction'] = txn;
            }
          }
        } else {
          // Clean up cache entry if the lot moved past WEIGHED (e.g., VERIFIED_COMPLETED)
          _txnCache.remove(backendId);
        }

        return mutable;
      }),
    );

    latestLotsNotifier.value = enrichedLots;
    return enrichedLots;
  }

  static void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _txnCache.clear();
  }
}
