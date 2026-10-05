import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/menu_item.dart';
import '../models/transaction.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'simple_kasir.db');

    final db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );

    // Pastikan tabel settings selalu ada (untuk migrasi/database yang sudah terbentuk)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Pastikan kolom paymentMethod selalu ada pada tabel transactions
    try {
      await db.execute("ALTER TABLE transactions ADD COLUMN paymentMethod TEXT DEFAULT 'Tunai'");
    } catch (_) {
      // Kolom sudah ada
    }

    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabel Pengaturan / Profil UMKM
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Default Profil UMKM
    await db.insert('settings', {
      'key': 'store_name',
      'value': 'KasirKu UMKM',
    });
    await db.insert('settings', {
      'key': 'store_address',
      'value': 'Semoga Usaha Anda Lancar & Berkah',
    });

    // Tabel Menu
    await db.execute('''
      CREATE TABLE menus (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        imagePath TEXT,
        category TEXT
      )
    ''');

    // Tabel Transaksi
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceNumber TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        cashReceived REAL NOT NULL,
        changeAmount REAL NOT NULL,
        paymentMethod TEXT DEFAULT 'Tunai',
        itemsJson TEXT NOT NULL
      )
    ''');
  }

  // --- CRUD Menu ---
  Future<List<MenuItem>> getMenus() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('menus', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => MenuItem.fromMap(maps[i]));
  }

  Future<int> insertMenu(MenuItem item) async {
    final db = await database;
    return await db.insert('menus', item.toMap());
  }

  Future<int> updateMenu(MenuItem item) async {
    final db = await database;
    return await db.update(
      'menus',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteMenu(int id) async {
    final db = await database;
    return await db.delete(
      'menus',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD Transaksi ---
  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Pengaturan / Profil UMKM ---
  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

