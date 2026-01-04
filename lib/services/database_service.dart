import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/memory.dart';
import '../models/user.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  static Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'romantic_memory.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Tabel Users
        await db.execute('''
          CREATE TABLE users(
            id TEXT PRIMARY KEY,
            email TEXT,
            password TEXT, 
            partnerEmail TEXT,
            displayName TEXT,
            profileImageUrl TEXT,
            createdAt TEXT,
            updatedAt TEXT
          )
        ''');

        // Tabel Memories
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

  // --- User Authentication (Local) ---

  Future<User?> signUp(
      String email, String password, String displayName) async {
    final db = await database;

    // Cek apakah email sudah ada
    final existing =
        await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (existing.isNotEmpty) {
      throw Exception('Email already exists');
    }

    // Buat ID baru (bisa pakai UUID dari model atau generate di sini)
    // Di sini kita asumsikan User model punya constructor yang generate ID jika null,
    // tapi karena method sign up di model User Anda butuh ID, kita generate dummy.
    final newUser = User(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(), // Simple ID generation
      email: email,
      displayName: displayName,
    );

    // Simpan user + password (perlu diingat: simpan password plain text di local db TIDAK AMAN untuk production, tapi oke untuk tugas kuliah/demo)
    final userMap = newUser.toMap();
    userMap['password'] =
        password; // Tambahkan field password untuk login nanti

    await db.insert('users', userMap);
    return newUser;
  }

  Future<User?> signIn(String email, String password) async {
    final db = await database;

    final maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    } else {
      throw Exception('Invalid email or password');
    }
  }

  Future<void> signOut() async {
    // Karena lokal, kita hanya perlu menghapus state di controller.
    // Tidak ada sesi server yang perlu dimatikan.
    return;
  }

  // --- Memory CRUD Operations ---

  Future<void> createMemory(Memory memory) async {
    final db = await database;
    // Konversi boolean isFavorite ke integer (0 atau 1) untuk SQLite
    final map = memory.toMap();
    map['isFavorite'] = memory.isFavorite ? 1 : 0;

    await db.insert('memories', map,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Memory>> getUserMemories(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'memories',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      final map = Map<String, dynamic>.from(maps[i]);
      // Kembalikan integer ke boolean
      map['isFavorite'] = map['isFavorite'] == 1;
      return Memory.fromMap(map);
    });
  }

  Future<void> updateMemory(Memory memory) async {
    final db = await database;
    final updated = memory.copyWith(updatedAt: DateTime.now());

    final map = updated.toMap();
    map['isFavorite'] = updated.isFavorite ? 1 : 0;

    await db.update(
      'memories',
      map,
      where: 'id = ?',
      whereArgs: [memory.id],
    );
  }

  Future<void> deleteMemory(String memoryId) async {
    final db = await database;
    await db.delete(
      'memories',
      where: 'id = ?',
      whereArgs: [memoryId],
    );
  }

  Future<void> toggleFavorite(String memoryId, bool isFavorite) async {
    final db = await database;
    await db.update(
      'memories',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [memoryId],
    );
  }

  // --- Local File Storage (Pengganti Firebase Storage) ---

  Future<String> saveFileLocally(String sourcePath, String subDirectory) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = basename(sourcePath);
    final savedDir = Directory('${directory.path}/$subDirectory');

    if (!await savedDir.exists()) {
      await savedDir.create(recursive: true);
    }

    final newPath =
        '${savedDir.path}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final File sourceFile = File(sourcePath);
    await sourceFile.copy(newPath);

    return newPath; // Kembalikan path lokal
  }
}
