import '../entities/debt.dart';

abstract interface class IDebtRepository {
  Future<List<Debt>> getPendingDebts(int clientId);
  Future<List<Debt>> getClientDebts(int clientId);
  Future<List<Debt>> getOldDebts(int daysThreshold);
  Future<int> createDebt(Debt debt);
  Future<void> markAsPaid(int debtId);
  Future<void> deleteDebt(int debtId);
  Stream<List<Debt>> watchClientDebts(int clientId);
}