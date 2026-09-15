import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _databaseName = "renova_offline.db";
  static const _databaseVersion = 1;

  // Singleton instance
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

    // 2. Price History Table (Mapped from CSV)
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
    // Overwrite or insert profile (id: 1)
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

  Future<List<Map<String, dynamic>>> getQueuedLots({int limit = 20}) async {
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

  // ==========================================================
  // CSV / PRICE HISTORY OPERATIONS
  // ==========================================================

  Future<void> insertPriceRecords(List<Map<String, dynamic>> records) async {
    final db = await database;
    final batch = db.batch();

    for (final row in records) {
      batch.insert('price_history', row);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getLatestPrices() async {
    final db = await database;
    return await db.query('price_history', orderBy: 'date DESC');
  }
}
