import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../services/local_ai_classifier.dart';
import '../constants/app_enums.dart';

class DatabaseHelper {
  static const _databaseName = "renova_offline.db";
  static const _databaseVersion = 3;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. User Profile Table
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        language TEXT DEFAULT 'english',
        latitude REAL,
        longitude REAL,
        address TEXT,
        updated_at TEXT
      )
    ''');

    // 2. Price History Table
    await db.execute('''
      CREATE TABLE price_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        location TEXT,
        material_category TEXT NOT NULL,
        material_sub_category TEXT NOT NULL,
        mandi_price_per_kg REAL NOT NULL,
        recycler_offered_price_per_kg REAL NOT NULL,
        min_market_price REAL NOT NULL,
        max_market_price REAL NOT NULL
      )
    ''');

    // 3. Offline Lot Single Source of Truth
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lot_uid TEXT NOT NULL UNIQUE,
        backend_id TEXT,
        image_path TEXT,
        json_payload TEXT,
        material_category TEXT,
        estimated_weight_kg REAL DEFAULT 1.0,
        qr_token TEXT,
        transaction_json TEXT,
        pending_action TEXT,
        status TEXT DEFAULT 'PENDING',
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE sync_queue ADD COLUMN backend_id TEXT;");
      } catch (_) {}
      try {
        await db.execute(
          "ALTER TABLE sync_queue ADD COLUMN material_category TEXT;",
        );
      } catch (_) {}
      try {
        await db.execute(
          "ALTER TABLE sync_queue ADD COLUMN estimated_weight_kg REAL DEFAULT 1.0;",
        );
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE sync_queue ADD COLUMN qr_token TEXT;");
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute(
          "ALTER TABLE sync_queue ADD COLUMN transaction_json TEXT;",
        );
      } catch (_) {}
      try {
        await db.execute(
          "ALTER TABLE sync_queue ADD COLUMN pending_action TEXT;",
        );
      } catch (_) {}
    }
  }

  // ==========================================================
  // SYNC QUEUE / LOT CRUD OPERATIONS
  // ==========================================================

  Future<int> enqueueLot({
    required String lotUid,
    required String imagePath,
    required String jsonPayload,
    String? materialCategory,
    double? estimatedWeightKg,
    String? qrToken,
  }) async {
    final db = await database;

    String category = materialCategory ?? 'MIXED_EWASTE_CASING';
    double weight = estimatedWeightKg ?? 1.0;
    String qr = qrToken ?? '';

    try {
      final decoded = jsonDecode(jsonPayload) as Map<String, dynamic>;
      category = materialCategory ?? decoded['material_category'] ?? category;
      weight =
          estimatedWeightKg ??
          (decoded['estimated_weight_kg'] as num?)?.toDouble() ??
          weight;
      qr = qrToken ?? decoded['qr_token'] ?? qr;
    } catch (_) {}

    return await db.insert('sync_queue', {
      'lot_uid': lotUid,
      'backend_id': null,
      'image_path': imagePath,
      'json_payload': jsonPayload,
      'material_category': category,
      'estimated_weight_kg': weight,
      'qr_token': qr,
      'transaction_json': null,
      'pending_action': null,
      'status': 'PENDING',
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getQueuedLots({int limit = 100}) async {
    final db = await database;
    final rows = await db.query(
      'sync_queue',
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return rows.map((row) {
      final mutable = Map<String, dynamic>.from(row);
      if (mutable['transaction_json'] != null &&
          (mutable['transaction_json'] as String).isNotEmpty) {
        try {
          mutable['transaction'] = jsonDecode(
            mutable['transaction_json'] as String,
          );
        } catch (_) {}
      }
      return mutable;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getPendingQueue() async {
    final db = await database;
    return await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['PENDING'],
      orderBy: 'created_at ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getLotsWithPendingAction() async {
    final db = await database;
    return await db.query(
      'sync_queue',
      where: 'pending_action IS NOT NULL AND pending_action != ?',
      whereArgs: [''],
    );
  }

  /// Fetches a single lot by matching either backend_id or lot_uid
  Future<Map<String, dynamic>?> getLotById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'sync_queue',
      where: 'backend_id = ? OR lot_uid = ?',
      whereArgs: [id, id],
      limit: 1,
    );

    if (results.isNotEmpty) {
      final mutable = Map<String, dynamic>.from(results.first);
      if (mutable['transaction_json'] != null &&
          (mutable['transaction_json'] as String).isNotEmpty) {
        try {
          mutable['transaction'] = jsonDecode(
            mutable['transaction_json'] as String,
          );
        } catch (_) {}
      }
      return mutable;
    }
    return null;
  }

  Future<int> updateLotStatus(
    String lotUidOrBackendId,
    String status, {
    String? backendId,
    Map<String, dynamic>? transaction,
    String? pendingAction,
  }) async {
    final db = await database;
    final Map<String, dynamic> updateValues = {'status': status};

    if (backendId != null && backendId.isNotEmpty) {
      updateValues['backend_id'] = backendId;
    }
    if (transaction != null) {
      updateValues['transaction_json'] = jsonEncode(transaction);
    }
    if (pendingAction != null) {
      updateValues['pending_action'] = pendingAction;
    }

    return await db.update(
      'sync_queue',
      updateValues,
      where: 'lot_uid = ? OR backend_id = ?',
      whereArgs: [lotUidOrBackendId, lotUidOrBackendId],
    );
  }

  Future<int> clearPendingAction(String lotUidOrBackendId) async {
    final db = await database;
    return await db.update(
      'sync_queue',
      {'pending_action': null},
      where: 'lot_uid = ? OR backend_id = ?',
      whereArgs: [lotUidOrBackendId, lotUidOrBackendId],
    );
  }

  Future<int> deleteLot(String identifier) async {
    final db = await database;
    return await db.delete(
      'sync_queue',
      where: 'lot_uid = ? OR backend_id = ?',
      whereArgs: [identifier, identifier],
    );
  }

  /// Single Source of Truth Reconciler:
  /// Merges server feed into SQLite while preserving device-only images and un-pushed actions.
  Future<void> reconcileSyncedLots(
    List<Map<String, dynamic>> remoteLots,
  ) async {
    final db = await database;

    final activeRemoteLots = remoteLots.where((r) {
      final status = (r['status'] ?? '').toString().toUpperCase();
      return status != 'CANCELLED' &&
          status != 'WITHDRAWN' &&
          status != 'ARCHIVED';
    }).toList();

    final remoteIds = activeRemoteLots
        .map((r) => (r['id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();
    final remoteClientUids = activeRemoteLots
        .map((r) => (r['client_lot_id'] ?? r['lot_uid'] ?? '').toString())
        .where((uid) => uid.isNotEmpty)
        .toSet();

    await db.transaction((txn) async {
      // 1. Remove synced records that no longer exist on server (unless local PENDING upload)
      final localRows = await txn.query('sync_queue');
      for (final row in localRows) {
        final localUid = (row['lot_uid'] ?? '').toString();
        final localBackendId = (row['backend_id'] ?? '').toString();
        final localStatus = (row['status'] ?? '').toString().toUpperCase();

        if (localStatus != 'PENDING' &&
            !remoteClientUids.contains(localUid) &&
            !remoteIds.contains(localBackendId)) {
          await txn.delete(
            'sync_queue',
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        }
      }

      // 2. Upsert each remote lot
      for (final r in activeRemoteLots) {
        final clientUid = (r['client_lot_id'] ?? r['lot_uid'] ?? '').toString();
        final backendId = (r['id'] ?? '').toString();
        final status = (r['status'] ?? 'SYNCED').toString().toUpperCase();
        final qrToken = (r['qr_token'] ?? '').toString();
        final category = (r['material_category'] ?? 'MIXED_EWASTE_CASING')
            .toString();
        final weight = (r['estimated_weight_kg'] as num?)?.toDouble() ?? 1.0;

        final existing = await txn.query(
          'sync_queue',
          where: 'lot_uid = ? OR (backend_id IS NOT NULL AND backend_id = ?)',
          whereArgs: [clientUid.isNotEmpty ? clientUid : backendId, backendId],
        );

        if (existing.isNotEmpty) {
          final row = existing.first;
          final localImage = (row['image_path'] ?? '') as String;
          final localPendingAction = row['pending_action'] as String?;

          // Don't downgrade status if we have an un-pushed local action pending
          final effectiveStatus =
              (localPendingAction != null && localPendingAction.isNotEmpty)
              ? (row['status'] as String)
              : status;

          await txn.update(
            'sync_queue',
            {
              'status': effectiveStatus,
              if (backendId.isNotEmpty) 'backend_id': backendId,
              if (qrToken.isNotEmpty) 'qr_token': qrToken,
              'material_category': category,
              'estimated_weight_kg': weight,
              if (localImage.isNotEmpty) 'image_path': localImage,
              'json_payload': jsonEncode(r),
            },
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        } else {
          await txn.insert('sync_queue', {
            'lot_uid': clientUid.isNotEmpty ? clientUid : backendId,
            'backend_id': backendId,
            'image_path': '',
            'json_payload': jsonEncode(r),
            'material_category': category,
            'estimated_weight_kg': weight,
            'qr_token': qrToken,
            'transaction_json': null,
            'pending_action': null,
            'status': status,
            'created_at':
                (r['created_at_local'] ??
                        r['synced_at'] ??
                        DateTime.now().toIso8601String())
                    .toString(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  // ==========================================================
  // BENCHMARKS, PROFILE & PRICE OPERATIONS
  // ==========================================================

  Future<void> seedInitialPricesIfNeeded() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM price_history'),
    );

    if (count == null || count == 0) {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      try {
        String jsonString = '';
        try {
          jsonString = await rootBundle.loadString(
            'assets/data/benchmark.json',
          );
        } catch (_) {
          try {
            jsonString = await rootBundle.loadString(
              'assets/price_benchmark.json',
            );
          } catch (_) {}
        }

        if (jsonString.isNotEmpty) {
          final dynamic decoded = jsonDecode(jsonString);
          final List<dynamic> list = decoded is List
              ? decoded
              : (decoded is Map
                  ? (decoded['benchmarks'] as List<dynamic>? ?? [])
                  : []);

          for (final item in list) {
            final map = Map<String, dynamic>.from(item as Map);
            await db.insert('price_history', {
              'date': map['date'] ?? today,
              'material_category': map['material_category'],
              'material_sub_category':
                  map['material_sub_category'] ?? map['material_category'],
              'mandi_price_per_kg':
                  (map['mandi_price_per_kg'] as num?)?.toDouble() ?? 50.0,
              'recycler_offered_price_per_kg':
                  (map['recycler_offered_price_per_kg'] as num?)?.toDouble() ??
                  50.0,
              'min_market_price':
                  (map['min_market_price'] as num?)?.toDouble() ?? 40.0,
              'max_market_price':
                  (map['max_market_price'] as num?)?.toDouble() ?? 60.0,
              'location': map['location'] ?? 'Bhubaneswar',
            });
          }
        }
      } catch (e) {
        debugPrint('Error reading benchmark assets: $e');
      }

      final checkCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM price_history'),
      );

      if (checkCount == null || checkCount == 0) {
        for (final code in LocalAiClassifier.canonicalCategories) {
          final b = LocalAiClassifier.benchmarks[code]!;
          await db.insert('price_history', {
            'date': today,
            'material_category': code,
            'material_sub_category': LocalAiClassifier.getLocalizedMaterialName(
              code,
              AppLanguage.english,
            ),
            'mandi_price_per_kg': (b['min_rate'] as num).toDouble(),
            'recycler_offered_price_per_kg': (b['rate_per_kg'] as num)
                .toDouble(),
            'min_market_price': (b['min_rate'] as num).toDouble(),
            'max_market_price': (b['max_rate'] as num).toDouble(),
            'location': 'Bhubaneswar',
          });
        }
      }
    }
  }

  Future<int> saveUserProfile({
    required String name,
    String? phone,
    String language = 'english',
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    final db = await database;
    return await db.insert('user_profile', {
      'id': 1,
      'name': name,
      'phone': phone,
      'language': language,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final db = await database;
    final res = await db.query('user_profile', where: 'id = 1');
    return res.isNotEmpty ? res.first : null;
  }

  Future<void> clearUserDataOnLogout() async {
    final db = await database;
    await db.delete('sync_queue');
    await db.delete('user_profile');
  }

  Future<List<Map<String, dynamic>>> getLatestPrices() async {
    final db = await database;
    return await db.query('price_history', orderBy: 'id ASC');
  }

  Future<void> saveBackendQuotes(List<dynamic> quotes, String city) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    await db.transaction((txn) async {
      await txn.delete('price_history');
      for (final raw in quotes) {
        final quote = Map<String, dynamic>.from(raw as Map);
        final code = (quote['material_code'] ?? '').toString();
        if (code.isEmpty) continue;

        final nameEn = (quote['name_en'] ?? code).toString();
        final buyRate = (quote['buy_rate_per_kg'] as num?)?.toDouble() ?? 0.0;
        final minRate =
            (quote['min_rate'] as num?)?.toDouble() ?? (buyRate * 0.85);
        final maxRate =
            (quote['max_rate'] as num?)?.toDouble() ?? (buyRate * 1.15);

        await txn.rawInsert(
          '''
          INSERT INTO price_history (
            date, material_category, material_sub_category,
            mandi_price_per_kg, recycler_offered_price_per_kg,
            min_market_price, max_market_price, location
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
          [today, code, nameEn, minRate, buyRate, minRate, maxRate, city],
        );
      }
    });
  }

  Future<void> clearAndReseedPrices() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    await db.transaction((txn) async {
      await txn.delete('price_history');

      for (final code in LocalAiClassifier.canonicalCategories) {
        final bench = LocalAiClassifier.benchmarks[code]!;
        final rate = (bench['rate_per_kg'] as num).toDouble();
        final minR = (bench['min_rate'] as num).toDouble();
        final maxR = (bench['max_rate'] as num).toDouble();
        final mandi = minR;

        await txn.rawInsert(
          '''
          INSERT INTO price_history (
            date,
            material_category,
            material_sub_category,
            mandi_price_per_kg,
            recycler_offered_price_per_kg,
            min_market_price,
            max_market_price,
            location
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
          [
            today,
            code,
            LocalAiClassifier.getLocalizedMaterialName(
              code,
              AppLanguage.english,
            ),
            mandi,
            rate,
            minR,
            maxR,
            'Bhubaneswar',
          ],
        );
      }
    });
  }
}
