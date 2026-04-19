import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database?> get database async {
    if (kIsWeb) return null; // 🛡️ WEB TIDAK PAKAI SQLITE
    if (_database != null) return _database!;
    _database = await _initDB('simpakab_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Tabel Peralatan (Equipment)
    await db.execute('''
      CREATE TABLE equipment (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT,
        stock INTEGER,
        image_url TEXT,
        last_sync TEXT
      )
    ''');

    // Tabel Peminjaman (Loans)
    await db.execute('''
      CREATE TABLE loans (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        equipment_id TEXT,
        status TEXT,
        borrow_date TEXT,
        return_date TEXT,
        full_name TEXT
      )
    ''');
  }

  // SIMPAN DATA ALAT (Update kalau sudah ada)
  Future<void> saveEquipment(List<Map<String, dynamic>> items) async {
    final db = await instance.database;
    if (db == null) return; // 🛡️ Keluar kalau di Web
    
    final batch = db.batch();
    for (var item in items) {
      batch.insert(
        'equipment',
        {
          'id': item['id'],
          'name': item['name'],
          'category': item['category'],
          'stock': item['stock'],
          'image_url': item['image_url'],
          'last_sync': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // AMBIL DATA ALAT OFFLINE
  Future<List<Map<String, dynamic>>> getEquipment() async {
    final db = await instance.database;
    if (db == null) return []; // 🛡️ Balikin list kosong kalau di Web
    return await db.query('equipment', orderBy: 'name ASC');
  }

  Future<void> close() async {
    final db = await instance.database;
    if (db != null) db.close();
  }
}
