// presentation/providers/sale_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database_helper.dart';
import '../../data/repositories/sale_repository.dart';
import '../../domain/entities/sale.dart';

// ─── Providers de repositorio ─────────────────────────

final saleRepositoryProvider = Provider<SaleRepository>(
  (ref) => SaleRepository(DatabaseHelper.instance),
);

// ─── Stats del dashboard ──────────────────────────────

final salesStatsProvider = FutureProvider<SalesDashboardStats>((ref) {
  return ref.watch(saleRepositoryProvider).getDashboardStats();
});

// ─── Lista de ventas con filtro de período ────────────

enum SalesPeriod { today, week, month, all }

class SalesNotifier extends StateNotifier<AsyncValue<List<Sale>>> {
  SalesNotifier(this._repo) : super(const AsyncValue.loading()) {
    load(SalesPeriod.all);
  }

  final SaleRepository _repo;
  SalesPeriod _currentPeriod = SalesPeriod.all;

  SalesPeriod get currentPeriod => _currentPeriod;

  Future<void> load(SalesPeriod period) async {
    _currentPeriod = period;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => switch (period) {
          SalesPeriod.today => _repo.getSalesToday(),
          SalesPeriod.week => _repo.getSalesThisWeek(),
          SalesPeriod.month => _repo.getSalesThisMonth(),
          SalesPeriod.all => _repo.getAllSales(),
        });
  }

  Future<void> refresh() => load(_currentPeriod);

  Future<void> addSale(Sale sale) async {
    try {
      await _repo.createSale(sale);
      await refresh();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> deleteSale(int id) async {
    try {
      await _repo.deleteSale(id);
      await refresh();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final salesProvider =
    StateNotifierProvider<SalesNotifier, AsyncValue<List<Sale>>>(
  (ref) => SalesNotifier(ref.watch(saleRepositoryProvider)),
);