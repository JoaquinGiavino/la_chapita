import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/i_debt_repository.dart';
import '../../domain/repositories/i_payment_repository.dart';
import 'database_provider.dart';

class DebtNotifier extends StateNotifier<AsyncValue<List<Debt>>> {
  DebtNotifier(this._debtRepo, this._paymentRepo, this._clientId)
      : super(const AsyncValue.loading()) {
    load();
  }

  final IDebtRepository _debtRepo;
  final IPaymentRepository _paymentRepo;
  final int _clientId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _debtRepo.getClientDebts(_clientId));
  }

  Future<void> addDebt(Debt debt) async {
    try {
      await _debtRepo.createDebt(debt);
      await load();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> registerPayment({
    required Payment payment,
    required double debtTotalAmount,
    required double currentPendingAmount,
  }) async {
    try {
      await _paymentRepo.registerPayment(payment);
      if (payment.amount >= currentPendingAmount - 0.005) {
        await _debtRepo.markAsPaid(payment.debtId);
      }
      await load();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> deleteDebt(int debtId) async {
    try {
      await _debtRepo.deleteDebt(debtId);
      await load();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final debtsByClientProvider = StateNotifierProvider.family<DebtNotifier, AsyncValue<List<Debt>>, int>(
  (ref, clientId) => DebtNotifier(
    ref.watch(debtRepositoryProvider),
    ref.watch(paymentRepositoryProvider),
    clientId,
  ),
);

final oldDebtsProvider = FutureProvider.family<List<Debt>, int>(
  (ref, days) => ref.watch(debtRepositoryProvider).getOldDebts(days),
);