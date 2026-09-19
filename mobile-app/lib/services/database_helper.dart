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
  static const _databaseVersion = 1;

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

    // 2. Price History Table (Mapped from unified benchmark JSON)
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

    // 3. Offline Lot Sync Queue
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lot_uid TEXT NOT NULL UNIQUE,
        image_path TEXT NOT NULL,
        json_payload TEXT NOT NULL,
        status TEXT DEFAULT 'PENDING',
        created_at TEXT NOT NULL
      )
    ''');
  }

  // ==========================================================
  // SEEDING & BENCHMARK OPERATIONS
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

      // Check if rows were successfully inserted; if not, insert canonical categories directly
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

  // ==========================================================
  // USER PROFILE OPERATIONS
  // ==========================================================

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

  // ==========================================================
  // SYNC QUEUE OPERATIONS
  // ==========================================================

  Future<int> enqueueLot({
    required String lotUid,
    required String imagePath,
    required String jsonPayload,
  }) async {
    final db = await database;
    return await db.insert('sync_queue', {
      'lot_uid': lotUid,
      'image_path': imagePath,
      'json_payload': jsonPayload,
      'status': 'PENDING',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getQueuedLots({int limit = 50}) async {
    final db = await database;
    return await db.query(
      'sync_queue',
      orderBy: 'created_at DESC',
      limit: limit,
    );
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

  Future<int> updateQueueStatus(int id, String status) async {
    final db = await database;
    return await db.update(
      'sync_queue',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateQueueStatusByLotUid(String lotUid, String status) async {
    final db = await database;
    return await db.update(
      'sync_queue',
      {'status': status},
      where: 'lot_uid = ?',
      whereArgs: [lotUid],
    );
  }

  // Clears user-specific offline lot cache and profile on logout
  Future<void> clearUserDataOnLogout() async {
    final db = await database;
    await db.delete('sync_queue');
    await db.delete('user_profile');
    // Note: Keeps price_history intact so offline benchmark rates remain available
  }

  // ==========================================================
  // PRICE HISTORY OPERATIONS
  // ==========================================================

  Future<void> insertPriceRecords(List<Map<String, dynamic>> records) async {
    final db = await database;
    final batch = db.batch();

    for (final row in records) {
      batch.insert('price_history', row);
    }
    await batch.commit(noResult: true);
  }

  /// Atomically refreshes prices when new rates arrive from backend sync
  Future<void> refreshPriceRecords(List<Map<String, dynamic>> records) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('price_history');
      for (final row in records) {
        await txn.insert('price_history', row);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getLatestPrices() async {
    final db = await database;
    return await db.query('price_history', orderBy: 'id ASC');
  }

  Future<void> saveBackendQuotes(List<dynamic> quotes, String city) async {
    final db = await instance.database;
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
          [today, code, nameEn, minRate, buyRate, minRate, maxRate, city],
        );
      }
    });
  }

  Future<void> reconcileSyncedLots(
    List<Map<String, dynamic>> remoteLots,
  ) async {
    final db = await database;

    // Only consider lots that are ACTIVE (exclude CANCELLED and COMPLETED from the active queue)
    final activeRemoteLots = remoteLots.where((r) {
      final status = (r['status'] ?? '').toString().toUpperCase();
      return status != 'CANCELLED';
    }).toList();

    final remoteUids = activeRemoteLots
        .map((r) => (r['client_lot_id'] ?? r['lot_uid'] ?? '').toString())
        .where((uid) => uid.isNotEmpty)
        .toSet();

    await db.transaction((txn) async {
      // 1. Remove any local synced row that is cancelled or gone from active backend lots
      final localRows = await txn.query(
        'sync_queue',
        where: 'status != ?',
        whereArgs: ['PENDING'],
      );

      for (final row in localRows) {
        final localUid = row['lot_uid'] as String;
        if (!remoteUids.contains(localUid)) {
          await txn.delete(
            'sync_queue',
            where: 'lot_uid = ?',
            whereArgs: [localUid],
          );
        }
      }

      // 2. Update the remaining active lots
      for (final r in activeRemoteLots) {
        final uid = (r['client_lot_id'] ?? r['lot_uid'] ?? '').toString();
        final status = (r['status'] ?? 'SYNCED').toString();
        if (uid.isNotEmpty) {
          await txn.update(
            'sync_queue',
            {'status': status},
            where: 'lot_uid = ?',
            whereArgs: [uid],
          );
        }
      }
    });
  }

  Future<void> clearAndReseedPrices() async {
    final db = await instance.database;
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
