import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/memory.dart';

/// Service untuk mengelola database SQLite lokal
/// Menyimpan semua data memories di device
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'romantic_memory.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create memories table
        await db.execute('''
          CREATE TABLE memories(
            id TEXT PRIMARY KEY,
            userId TEXT,
            title TEXT,
            description TEXT,
            imageUrl TEXT,
            date TEXT,
            location TEXT,
            latitude REAL,
            longitude REAL,
            audioUrl TEXT,
            isFavorite INTEGER,
            createdAt TEXT,
            updatedAt TEXT
          )
        ''');
      },
    );
  }

  // ==================== MEMORY CRUD OPERATIONS ====================

  /// Create new memory
  Future<void> createMemory(Memory memory) async {
    final db = await database;

    // Convert boolean to integer for SQLite
    Map<String, dynamic> map = memory.toMap();
    map['isFavorite'] = memory.isFavorite ? 1 : 0;

    await db.insert(
      'memories',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Read all memories for a user
  Future<List<Memory>> getMemories(String userId) async {
    final db = await database;

    // Get all memories ordered by date (newest first)
    final List<Map<String, dynamic>> maps = await db.query(
      'memories',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      Map<String, dynamic> map = Map<String, dynamic>.from(maps[i]);
      // Convert integer back to boolean
      map['isFavorite'] = map['isFavorite'] == 1;
      return Memory.fromMap(map);
    });
  }

  /// Read single memory by ID
  Future<Memory?> getMemoryById(String id) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'memories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    Map<String, dynamic> map = Map<String, dynamic>.from(maps.first);
    map['isFavorite'] = map['isFavorite'] == 1;
    return Memory.fromMap(map);
  }

  /// Update existing memory
  Future<void> updateMemory(Memory memory) async {
    final db = await database;

    Map<String, dynamic> map = memory.toMap();
    map['isFavorite'] = memory.isFavorite ? 1 : 0;
    map['updatedAt'] = DateTime.now().toIso8601String();

    await db.update(
      'memories',
      map,
      where: 'id = ?',
      whereArgs: [memory.id],
    );
  }

  /// Delete memory
  Future<void> deleteMemory(String id) async {
    final db = await database;

    await db.delete(
      'memories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final db = await database;

    await db.update(
      'memories',
      {
        'isFavorite': isFavorite ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get favorite memories only
  Future<List<Memory>> getFavoriteMemories(String userId) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'memories',
      where: 'userId = ? AND isFavorite = ?',
      whereArgs: [userId, 1],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      Map<String, dynamic> map = Map<String, dynamic>.from(maps[i]);
      map['isFavorite'] = map['isFavorite'] == 1;
      return Memory.fromMap(map);
    });
  }

  /// Search memories by title or description
  Future<List<Memory>> searchMemories(String userId, String query) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'memories',
      where: 'userId = ? AND (title LIKE ? OR description LIKE ?)',
      whereArgs: [userId, '%$query%', '%$query%'],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      Map<String, dynamic> map = Map<String, dynamic>.from(maps[i]);
      map['isFavorite'] = map['isFavorite'] == 1;
      return Memory.fromMap(map);
    });
  }

  /// Get memories count
  Future<int> getMemoriesCount(String userId) async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM memories WHERE userId = ?',
      [userId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Delete all memories for a user (use with caution!)
  Future<void> deleteAllMemories(String userId) async {
    final db = await database;

    await db.delete(
      'memories',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
