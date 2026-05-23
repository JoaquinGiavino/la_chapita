import '../entities/client.dart';

abstract interface class IClientRepository {
  Future<List<Client>> getActiveClients();
  Future<List<Client>> searchClients(String query);
  Future<List<ClientDebtSummary>> getClientDebtSummaries();
  Future<Client?> getClientById(int id);
  Future<int> createClient(Client client);
  Future<void> updateClient(Client client);
  Future<void> deleteClient(int id);
  Stream<List<Client>> watchActiveClients();
}