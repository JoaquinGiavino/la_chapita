import '../../domain/entities/client.dart';
import '../../domain/repositories/i_client_repository.dart';
import '../database/database_helper.dart';

class ClientRepository implements IClientRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  @override
  Future<List<Client>> getActiveClients() async {
    final maps = await _db.getActiveClients();
    return maps.map((map) => Client(
      id: map['id'] as int,
      name: map['name'] as String,
      phone: map['phone'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isActive: map['isActive'] == 1,
    )).toList();
  }

  @override
  Future<List<Client>> searchClients(String query) async {
    final maps = await _db.searchClients(query);
    return maps.map((map) => Client(
      id: map['id'] as int,
      name: map['name'] as String,
      phone: map['phone'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isActive: map['isActive'] == 1,
    )).toList();
  }

  @override
  Future<Client?> getClientById(int id) async {
    final map = await _db.getClientById(id);
    if (map == null) return null;
    return Client(
      id: map['id'] as int,
      name: map['name'] as String,
      phone: map['phone'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isActive: map['isActive'] == 1,
    );
  }

  @override
  Future<int> createClient(Client client) async {
    return await _db.insertClient({
      'name': client.name,
      'phone': client.phone,
      'createdAt': client.createdAt.toIso8601String(),
      'isActive': client.isActive ? 1 : 0,
    });
  }

  @override
  Future<void> updateClient(Client client) async {
    await _db.updateClient({
      'id': client.id,
      'name': client.name,
      'phone': client.phone,
      'createdAt': client.createdAt.toIso8601String(),
      'isActive': client.isActive ? 1 : 0,
    });
  }

  @override
  Future<void> deleteClient(int id) async {
    await _db.deleteClient(id);
  }

  @override
  Future<void> deactivateClient(int id) async {
    await _db.updateClient({
      'id': id,
      'isActive': 0,
    });
  }

  @override
  Future<List<ClientDebtSummary>> getClientDebtSummaries() async {
    final clients = await getActiveClients();
    final summaries = <ClientDebtSummary>[];
    
    for (final client in clients) {
      final debts = await _db.getClientDebts(client.id);
      double pendingAmount = 0;
      int productCount = 0;
      DateTime? lastDebtDate;
      
      for (final debt in debts) {
        if (debt['isPaid'] == 0) {
          final paid = await _db.getTotalPaidForDebt(debt['id']);
          final pending = (debt['totalAmount'] as num).toDouble() - paid;
          pendingAmount += pending;
          productCount++;
          final debtDate = DateTime.parse(debt['date']);
          if (lastDebtDate == null || debtDate.isAfter(lastDebtDate)) {
            lastDebtDate = debtDate;
          }
        }
      }
      
      summaries.add(ClientDebtSummary(
        client: client,
        totalDebt: pendingAmount,
        pendingAmount: pendingAmount,
        productCount: productCount,
        lastDebtDate: lastDebtDate,
      ));
    }
    
    summaries.sort((a, b) => b.pendingAmount.compareTo(a.pendingAmount));
    return summaries;
  }

  @override
  Stream<List<Client>> watchActiveClients() async* {
    yield await getActiveClients();
  }
}