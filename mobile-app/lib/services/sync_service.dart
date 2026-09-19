import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'database_helper.dart';
import 'storage_service.dart';

class SyncService {
  /// Canonical set of 9 backend-recognized material codes
  static const Set<String> canonicalCategories = {
    'MOTHERBOARD_HIGH_GRADE',
    'POWER_SUPPLY_LOW_GRADE',
    'BATTERY_LITHIUM_PORTABLE',
    'LEAD_ACID',
    'CRT_MONITOR',
    'LCD_PANEL_INTACT',
    'MIXED_EWASTE_CASING',
    'COPPER_HEAVY_INSULATED',
    'ALUMINIUM_WIRE',
  };

  /// Normalizes material strings to canonical categories, with legacy fallback
  static String normalizeCategory(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'MIXED_EWASTE_CASING';
    }

    final clean = raw.trim().toUpperCase();

    // 1. Direct match if already using canonical enum string
    if (canonicalCategories.contains(clean)) {
      return clean;
    }

    // 2. Fallback normalization for legacy/informal inputs
    if (clean.contains('HIGH') ||
        (clean.contains('MOTHERBOARD') && !clean.contains('LOW'))) {
      return 'MOTHERBOARD_HIGH_GRADE';
    } else if (clean.contains('LOW') ||
        clean.contains('SMPS') ||
        clean.contains('SUPPLY')) {
      return 'POWER_SUPPLY_LOW_GRADE';
    } else if (clean.contains('COPPER') ||
        (clean.contains('WIRE') &&
            !clean.contains('ALUMINIUM') &&
            !clean.contains('ALUMINUM'))) {
      return 'COPPER_HEAVY_INSULATED';
    } else if (clean.contains('ALUMINIUM') || clean.contains('ALUMINUM')) {
      return 'ALUMINIUM_WIRE';
    } else if (clean.contains('LITHIUM') ||
        clean.contains('LI_ION') ||
        clean.contains('BATT')) {
      return 'BATTERY_LITHIUM_PORTABLE';
    } else if (clean.contains('LEAD') || clean.contains('ACID')) {
      return 'LEAD_ACID';
    } else if (clean.contains('CRT')) {
      return 'CRT_MONITOR';
    } else if (clean.contains('LCD') ||
        clean.contains('LED') ||
        clean.contains('DISPLAY') ||
        clean.contains('PANEL')) {
      return 'LCD_PANEL_INTACT';
    } else if (clean.contains('PLASTIC') || clean.contains('CASING')) {
      return 'MIXED_EWASTE_CASING';
    }

    return 'MIXED_EWASTE_CASING';
  }

  /// Syncs all PENDING lots from local SQLite to FastAPI
  static Future<Map<String, dynamic>> syncPendingLots({
    required ReNovaStorage storage,
  }) async {
    final token = storage.accessToken;
    if (token == null || token.isEmpty) {
      return {
        'success': false,
        'syncedCount': 0,
        'message': 'Collector is not logged in. Missing access token.',
      };
    }

    final pendingQueue = await DatabaseHelper.instance.getPendingQueue();
    if (pendingQueue.isEmpty) {
      return {
        'success': true,
        'syncedCount': 0,
        'message': 'Everything is already up to date.',
      };
    }

    final List<Map<String, dynamic>> lotsPayload = [];
    final List<int> queuedDbIds = [];

    for (final row in pendingQueue) {
      final dbId = row['id'] as int;
      final imagePath = row['image_path'] as String?;
      final jsonStr = row['json_payload'] as String? ?? '{}';

      Map<String, dynamic> localData = {};
      try {
        localData = jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (_) {}

      // Encode image to base64 if present
      String? photoBase64;
      if (imagePath != null && File(imagePath).existsSync()) {
        try {
          final bytes = await File(imagePath).readAsBytes();
          photoBase64 = base64Encode(bytes);
        } catch (_) {}
      }

      final rawCat =
          localData['material_category']?.toString() ??
          localData['category']?.toString();
      final canonicalCat = normalizeCategory(rawCat);

      final weight =
          (localData['approx_weight_kg'] as num? ??
                  localData['weight'] as num? ??
                  localData['estimated_weight_kg'] as num? ??
                  1.0)
              .toDouble();

      final clientLotId =
          localData['lot_uid']?.toString() ??
          localData['client_lot_id']?.toString() ??
          'lot_${DateTime.now().millisecondsSinceEpoch}_$dbId';

      final qrToken =
          localData['qr_token']?.toString() ??
          'QR_${clientLotId}_${storage.collectorId}';

      final lat = (localData['latitude'] as num?)?.toDouble() ?? 20.2961;
      final lon = (localData['longitude'] as num?)?.toDouble() ?? 85.8245;

      lotsPayload.add({
        'client_lot_id': clientLotId,
        'material_category': canonicalCat,
        'estimated_weight_kg': weight,
        'classification': {
          'label': canonicalCat,
          'confidence': (localData['confidence'] as num? ?? 0.95).toDouble(),
          'model_version': 'mobile-v1',
        },
        'city': storage.location ?? 'Bhubaneswar',
        'latitude': lat,
        'longitude': lon,
        'qr_token': qrToken,
        'photo_base64': photoBase64,
        'created_at_local':
            localData['created_at']?.toString() ??
            localData['created_at_local']?.toString() ??
            DateTime.now().toIso8601String(),
      });

      queuedDbIds.add(dbId);
    }

    final url = Uri.parse('${AuthService.baseUrl}/api/v1/lots/sync');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'lots': lotsPayload}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        for (final id in queuedDbIds) {
          await DatabaseHelper.instance.updateQueueStatus(id, 'SYNCED');
        }

        return {
          'success': true,
          'syncedCount': queuedDbIds.length,
          'message': 'Successfully synced ${queuedDbIds.length} scrap lots!',
        };
      } else {
        try {
          final err = jsonDecode(response.body);
          return {
            'success': false,
            'syncedCount': 0,
            'message':
                err['message'] ?? 'Server error (${response.statusCode})',
          };
        } catch (_) {
          return {
            'success': false,
            'syncedCount': 0,
            'message': 'Server error (${response.statusCode})',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'syncedCount': 0,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<bool> cancelLot({
    required ReNovaStorage storage,
    required String lotId,
  }) async {
    final token = storage.accessToken;
    if (token == null || token.isEmpty) return false;

    final url = Uri.parse('${AuthService.baseUrl}/api/v1/lots/$lotId/cancel');
    try {
      final res = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[SyncService] Failed to cancel lot: $e');
      return false;
    }
  }

  /// Submits collector dual-consent and payment confirmation for a weighed lot
  static Future<bool> submitConsent({
    required ReNovaStorage storage,
    required String lotId,
    required bool accepted,
    String paymentMode = 'UPI',
    String? upiReference,
  }) async {
    final token = storage.accessToken;
    if (token == null || token.isEmpty) return false;

    final url = Uri.parse('${AuthService.baseUrl}/api/v1/lots/$lotId/consent');

    try {
      final res = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'accepted': accepted,
              'payment_mode': paymentMode,
              'upi_reference':
                  upiReference ??
                  'UPI_${DateTime.now().millisecondsSinceEpoch}',
            }),
          )
          .timeout(const Duration(seconds: 10));

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[SyncService] Failed to submit consent: $e');
      return false;
    }
  }

  /// Fetches real-time status and transaction breakdown (certified weight & rate)
  static Future<Map<String, dynamic>?> fetchLotStatus({
    required ReNovaStorage storage,
    required String lotId,
  }) async {
    final token = storage.accessToken;
    if (token == null || token.isEmpty) return null;

    final url = Uri.parse('${AuthService.baseUrl}/api/v1/lots/$lotId/status');
    try {
      final res = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return decoded['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('[SyncService] Failed to fetch lot status: $e');
    }
    return null;
  }

  /// Fetches latest lots from backend to pull lifecycle status (BROADCASTED, LOCKED, SESSION_OPEN, etc.)
  static Future<List<Map<String, dynamic>>> fetchCollectorLots({
    required ReNovaStorage storage,
  }) async {
    final token = storage.accessToken;
    if (token == null || token.isEmpty) return [];

    final url = Uri.parse('${AuthService.baseUrl}/api/v1/collectors/me/lots');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        final List<dynamic> lotsData = decoded['data'] ?? [];
        final remoteLots = lotsData
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        // Update local SQLite cache using the string UID
        for (final rLot in remoteLots) {
          final uid = rLot['client_lot_id'] ?? rLot['lot_uid'];
          final status = rLot['status'];
          if (uid != null && status != null) {
            await DatabaseHelper.instance.updateQueueStatusByLotUid(
              uid.toString(),
              status.toString(),
            );
          }
        }

        return remoteLots;
      }
    } catch (e) {
      debugPrint('[SyncService] Failed to fetch collector lots: $e');
    }

    return [];
  }
}
