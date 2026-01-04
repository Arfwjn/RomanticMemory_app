import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/memory.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'romantic_memory.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
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

  // Create
  Future<void> createMemory(Memory memory) async {
    final db = await database;
    // Konversi boolean ke integer untuk SQLite
    Map<String, dynamic> map = memory.toMap();
    map['isFavorite'] = memory.isFavorite ? 1 : 0;
    await db.insert('memories', map,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Read
  Future<List<Memory>> getMemories(String userId) async {
    final db = await database;
    // Kita ambil semua memori (filter userId opsional jika single user)
    final List<Map<String, dynamic>> maps = await db.query(
      'memories',
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      Map<String, dynamic> map = Map<String, dynamic>.from(maps[i]);
      // Kembalikan integer ke boolean
      map['isFavorite'] = map['isFavorite'] == 1;
      return Memory.fromMap(map);
    });
  }

  // Update
  Future<void> updateMemory(Memory memory) async {
    final db = await database;
    Map<String, dynamic> map = memory.toMap();
    map['isFavorite'] = memory.isFavorite ? 1 : 0;

    await db.update(
      'memories',
      map,
      where: 'id = ?',
      whereArgs: [memory.id],
    );
  }

  // Delete
  Future<void> deleteMemory(String id) async {
    final db = await database;
    await db.delete(
      'memories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Toggle Favorite
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final db = await database;
    await db.update(
      'memories',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
