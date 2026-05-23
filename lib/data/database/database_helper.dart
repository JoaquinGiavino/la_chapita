import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('la_chapita.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabla de clientes
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        createdAt TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Tabla de deudas
    await db.execute('''
      CREATE TABLE debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientId INTEGER NOT NULL,
        productDescription TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        unitPrice REAL NOT NULL,
        totalAmount REAL NOT NULL,
        date TEXT NOT NULL,
        isPaid INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        FOREIGN KEY (clientId) REFERENCES clients (id) ON DELETE CASCADE
      )
    ''');

    // Tabla de pagos
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        debtId INTEGER NOT NULL,
        amount REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (debtId) REFERENCES debts (id) ON DELETE CASCADE
      )
    ''');
  }

  // ─── Clientes ─────────────────────────────────────────

  Future<int> insertClient(Map<String, dynamic> client) async {
    final db = await database;
    return await db.insert('clients', client);
  }

  Future<List<Map<String, dynamic>>> getActiveClients() async {
    final db = await database;
    return await db.query(
      'clients',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
  }

  Future<List<Map<String, dynamic>>> searchClients(String query) async {
    final db = await database;
    return await db.query(
      'clients',
      where: 'isActive = 1 AND (name LIKE ? OR phone LIKE ?)',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
  }

  Future<Map<String, dynamic>?> getClientById(int id) async {
    final db = await database;
    final result = await db.query(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateClient(Map<String, dynamic> client) async {
    final db = await database;
    return await db.update(
      'clients',
      client,
      where: 'id = ?',
      whereArgs: [client['id']],
    );
  }

  Future<int> deleteClient(int id) async {
    final db = await database;
    return await db.delete(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── Deudas ──────────────────────────────────────────

  Future<int> insertDebt(Map<String, dynamic> debt) async {
    final db = await database;
    return await db.insert('debts', debt);
  }

  Future<List<Map<String, dynamic>>> getClientDebts(int clientId) async {
    final db = await database;
    return await db.query(
      'debts',
      where: 'clientId = ?',
      whereArgs: [clientId],
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getOldDebts(int days) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    return await db.query(
      'debts',
      where: 'isPaid = 0 AND date <= ?',
      whereArgs: [cutoff],
      orderBy: 'date ASC',
    );
  }

  Future<int> updateDebt(Map<String, dynamic> debt) async {
    final db = await database;
    return await db.update(
      'debts',
      debt,
      where: 'id = ?',
      whereArgs: [debt['id']],
    );
  }

  Future<int> deleteDebt(int id) async {
    final db = await database;
    return await db.delete(
      'debts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── Pagos ───────────────────────────────────────────

  Future<int> insertPayment(Map<String, dynamic> payment) async {
    final db = await database;
    return await db.insert('payments', payment);
  }

  Future<List<Map<String, dynamic>>> getPaymentsByDebt(int debtId) async {
    final db = await database;
    return await db.query(
      'payments',
      where: 'debtId = ?',
      whereArgs: [debtId],
      orderBy: 'date DESC',
    );
  }

  Future<double> getTotalPaidForDebt(int debtId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM payments WHERE debtId = ?',
      [debtId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> deletePayment(int id) async {
    final db = await database;
    return await db.delete(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}