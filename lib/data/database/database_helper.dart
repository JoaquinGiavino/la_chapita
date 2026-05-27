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
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        createdAt TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

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

    await db.execute(_createSalesTableSQL);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(_createSalesTableSQL);
      // Migrar métodos de pago antiguos a los nuevos
      await db.execute("UPDATE sales SET paymentMethod = 'visa_debito' WHERE paymentMethod = 'visa'");
      await db.execute("UPDATE sales SET paymentMethod = 'mastercard_debito' WHERE paymentMethod = 'mastercard'");
    }
  }

  static const String _createSalesTableSQL = '''
    CREATE TABLE IF NOT EXISTS sales (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      productDescription TEXT NOT NULL,
      quantity INTEGER NOT NULL DEFAULT 1,
      unitPrice REAL NOT NULL,
      totalAmount REAL NOT NULL,
      paidAmount REAL NOT NULL DEFAULT 0,
      pendingAmount REAL NOT NULL DEFAULT 0,
      paymentMethod TEXT,
      clientId INTEGER,
      debtId INTEGER,
      isFullyPaid INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (clientId) REFERENCES clients (id) ON DELETE SET NULL,
      FOREIGN KEY (debtId) REFERENCES debts (id) ON DELETE SET NULL
    )
  ''';

  // ════════════════════════════════════════════════════════
  // ─── CLIENTES ────────────────────────────────────────────
  // ════════════════════════════════════════════════════════

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
    final result = await db.query('clients', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateClient(Map<String, dynamic> client) async {
    final db = await database;
    return await db.update('clients', client, where: 'id = ?', whereArgs: [client['id']]);
  }

  Future<int> deleteClient(int id) async {
    final db = await database;
    return await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  // ════════════════════════════════════════════════════════
  // ─── DEUDAS ──────────────────────────────────────────────
  // ════════════════════════════════════════════════════════

  Future<int> insertDebt(Map<String, dynamic> debt) async {
    final db = await database;
    return await db.insert('debts', debt);
  }

  Future<List<Map<String, dynamic>>> getClientDebts(int clientId) async {
    final db = await database;
    return await db.query('debts', where: 'clientId = ?', whereArgs: [clientId], orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> getOldDebts(int days) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    return await db.query('debts', where: 'isPaid = 0 AND date <= ?', whereArgs: [cutoff], orderBy: 'date ASC');
  }

  Future<int> updateDebt(Map<String, dynamic> debt) async {
    final db = await database;
    return await db.update('debts', debt, where: 'id = ?', whereArgs: [debt['id']]);
  }

  Future<int> deleteDebt(int id) async {
    final db = await database;
    return await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  // ════════════════════════════════════════════════════════
  // ─── PAGOS ───────────────────────────────────────────────
  // ════════════════════════════════════════════════════════

  Future<int> insertPayment(Map<String, dynamic> payment) async {
    final db = await database;
    return await db.insert('payments', payment);
  }

  Future<List<Map<String, dynamic>>> getPaymentsByDebt(int debtId) async {
    final db = await database;
    return await db.query('payments', where: 'debtId = ?', whereArgs: [debtId], orderBy: 'date DESC');
  }

  Future<double> getTotalPaidForDebt(int debtId) async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(amount) as total FROM payments WHERE debtId = ?', [debtId]);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> deletePayment(int id) async {
    final db = await database;
    return await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  // ════════════════════════════════════════════════════════
  // ─── VENTAS ──────────────────────────────────────────────
  // ════════════════════════════════════════════════════════

  Future<int> insertSale(Map<String, dynamic> sale) async {
    final db = await database;
    return await db.insert('sales', sale);
  }

  Future<List<Map<String, dynamic>>> getAllSales() async {
    final db = await database;
    return await db.query('sales', orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> getSalesByDateRange(String from, String to) async {
    final db = await database;
    return await db.query('sales', where: 'date >= ? AND date <= ?', whereArgs: [from, to], orderBy: 'date DESC');
  }

  Future<double> getTotalSalesAmount(String from, String to) async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(paidAmount) as total FROM sales WHERE date >= ? AND date <= ?', [from, to]);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalPendingSalesAmount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(pendingAmount) as total FROM sales WHERE isFullyPaid = 0');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> getSalesToday() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day).toIso8601String();
    final to = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();
    return getSalesByDateRange(from, to);
  }

  Future<List<Map<String, dynamic>>> getSalesThisWeek() async {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final from = DateTime(monday.year, monday.month, monday.day).toIso8601String();
    final to = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();
    return getSalesByDateRange(from, to);
  }

  Future<List<Map<String, dynamic>>> getSalesThisMonth() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1).toIso8601String();
    final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59).toIso8601String();
    return getSalesByDateRange(from, to);
  }

  Future<SalesDashboardStats> getSalesDashboardStats() async {
    final now = DateTime.now();

    final todayFrom = DateTime(now.year, now.month, now.day).toIso8601String();
    final todayTo = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekFrom = DateTime(monday.year, monday.month, monday.day).toIso8601String();

    final monthFrom = DateTime(now.year, now.month, 1).toIso8601String();

    final db = await database;

    Future<double> sum(String from, String to) async {
      final r = await db.rawQuery('SELECT SUM(paidAmount) as t FROM sales WHERE date >= ? AND date <= ?', [from, to]);
      return (r.first['t'] as num?)?.toDouble() ?? 0.0;
    }

    Future<int> count(String from, String to) async {
      final r = await db.rawQuery('SELECT COUNT(*) as c FROM sales WHERE date >= ? AND date <= ?', [from, to]);
      return (r.first['c'] as num?)?.toInt() ?? 0;
    }

    final end = todayTo;

    return SalesDashboardStats(
      todayAmount: await sum(todayFrom, todayTo),
      todayCount: await count(todayFrom, todayTo),
      weekAmount: await sum(weekFrom, end),
      weekCount: await count(weekFrom, end),
      monthAmount: await sum(monthFrom, end),
      monthCount: await count(monthFrom, end),
    );
  }

  Future<int> updateSalePaidAmount({required int saleId, required double newPaidAmount, required double totalAmount}) async {
    final db = await database;
    final pending = (totalAmount - newPaidAmount).clamp(0.0, double.infinity);
    return await db.update('sales', {
      'paidAmount': newPaidAmount,
      'pendingAmount': pending,
      'isFullyPaid': pending <= 0.005 ? 1 : 0,
    }, where: 'id = ?', whereArgs: [saleId]);
  }

  Future<Map<String, dynamic>?> getSaleByDebtId(int debtId) async {
    final db = await database;
    final result = await db.query('sales', where: 'debtId = ?', whereArgs: [debtId]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> deleteSale(int id) async {
    final db = await database;
    return await db.delete('sales', where: 'id = ?', whereArgs: [id]);
  }
}

class SalesDashboardStats {
  const SalesDashboardStats({
    required this.todayAmount,
    required this.todayCount,
    required this.weekAmount,
    required this.weekCount,
    required this.monthAmount,
    required this.monthCount,
  });

  final double todayAmount;
  final int todayCount;
  final double weekAmount;
  final int weekCount;
  final double monthAmount;
  final int monthCount;
}