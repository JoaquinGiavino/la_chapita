import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/client.dart';
import '../../domain/repositories/i_client_repository.dart';
import 'database_provider.dart';

class ClientsNotifier extends StateNotifier<AsyncValue<List<Client>>> {
  ClientsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final IClientRepository _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.getActiveClients);
  }

  Future<void> addClient(Client client) async {
    try {
      await _repo.createClient(client);
      await load();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> updateClient(Client client) async {
    try {
      await _repo.updateClient(client);
      await load();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> deleteClient(int id) async {
    try {
      await _repo.deleteClient(id);
      await load();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final clientsProvider = StateNotifierProvider<ClientsNotifier, AsyncValue<List<Client>>>(
  (ref) => ClientsNotifier(ref.watch(clientRepositoryProvider)),
);

final clientByIdProvider = FutureProvider.family<Client?, int>(
  (ref, id) => ref.watch(clientRepositoryProvider).getClientById(id),
);

final clientDebtSummariesProvider = FutureProvider<List<ClientDebtSummary>>(
  (ref) {
    ref.watch(clientsProvider);
    return ref.watch(clientRepositoryProvider).getClientDebtSummaries();
  },
);