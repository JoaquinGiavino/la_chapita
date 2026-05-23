// data/repositories/sale_repository.dart
import '../database/database_helper.dart';
import '../../domain/entities/sale.dart';

class SaleRepository {
  SaleRepository(this._db);
  final DatabaseHelper _db;

  /// Registra una venta nueva y retorna el ID.
  Future<int> createSale(Sale sale) async {
    return await _db.insertSale(sale.toMap());
  }

  /// Todas las ventas, ordenadas por fecha descendente.
  Future<List<Sale>> getAllSales() async {
    final maps = await _db.getAllSales();
    return _enrichWithClientNames(maps);
  }

  /// Ventas de hoy.
  Future<List<Sale>> getSalesToday() async {
    final maps = await _db.getSalesToday();
    return _enrichWithClientNames(maps);
  }

  /// Ventas de esta semana.
  Future<List<Sale>> getSalesThisWeek() async {
    final maps = await _db.getSalesThisWeek();
    return _enrichWithClientNames(maps);
  }

  /// Ventas de este mes.
  Future<List<Sale>> getSalesThisMonth() async {
    final maps = await _db.getSalesThisMonth();
    return _enrichWithClientNames(maps);
  }

  /// Stats para el dashboard.
  Future<SalesDashboardStats> getDashboardStats() async {
    return await _db.getSalesDashboardStats();
  }

  /// Actualiza paidAmount cuando se paga una deuda asociada.
  Future<void> updatePaidAmount({
    required int saleId,
    required double newPaidAmount,
    required double totalAmount,
  }) async {
    await _db.updateSalePaidAmount(
      saleId: saleId,
      newPaidAmount: newPaidAmount,
      totalAmount: totalAmount,
    );
  }

  /// Obtiene la venta ligada a una deuda (puede ser null).
  Future<Sale?> getSaleByDebtId(int debtId) async {
    final map = await _db.getSaleByDebtId(debtId);
    if (map == null) return null;
    return Sale.fromMap(map);
  }

  Future<void> deleteSale(int id) async {
    await _db.deleteSale(id);
  }

  // ─── Helper: enriquecer con nombre del cliente ────────
  // Hace una consulta extra por cada venta con clientId.
  // Para listas grandes convendría un JOIN, pero dada la escala
  // de la app esto es suficiente y mantiene el código simple.
  Future<List<Sale>> _enrichWithClientNames(
      List<Map<String, dynamic>> maps) async {
    final result = <Sale>[];
    for (final map in maps) {
      String? clientName;
      final clientId = map['clientId'] as int?;
      if (clientId != null) {
        final clientMap = await _db.getClientById(clientId);
        clientName = clientMap?['name'] as String?;
      }
      result.add(Sale.fromMap(map, clientName: clientName));
    }
    return result;
  }
}