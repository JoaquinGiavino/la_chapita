import '../../domain/entities/debt.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/i_debt_repository.dart';
import '../database/database_helper.dart';
import '../../domain/enums/payment_method.dart';

class DebtRepository implements IDebtRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  @override
  Future<List<Debt>> getPendingDebts(int clientId) async {
    final allDebts = await _db.getClientDebts(clientId);
    final pending = <Debt>[];
    
    for (final debtMap in allDebts) {
      if (debtMap['isPaid'] == 0) {
        final paid = await _db.getTotalPaidForDebt(debtMap['id']);
        final pendingAmount = (debtMap['totalAmount'] as num).toDouble() - paid;
        if (pendingAmount > 0) {
          pending.add(await _mapToDebt(debtMap));
        }
      }
    }
    return pending;
  }

  @override
  Future<List<Debt>> getClientDebts(int clientId) async {
    final maps = await _db.getClientDebts(clientId);
    final debts = <Debt>[];
    for (final map in maps) {
      debts.add(await _mapToDebt(map));
    }
    return debts;
  }

  @override
  Future<List<Debt>> getOldDebts(int daysThreshold) async {
    final maps = await _db.getOldDebts(daysThreshold);
    final debts = <Debt>[];
    for (final map in maps) {
      debts.add(await _mapToDebt(map));
    }
    return debts;
  }

  @override
  Future<int> createDebt(Debt debt) async {
    return await _db.insertDebt({
      'clientId': debt.clientId,
      'productDescription': debt.productDescription,
      'quantity': debt.quantity,
      'unitPrice': debt.unitPrice,
      'totalAmount': debt.totalAmount,
      'date': debt.date.toIso8601String(),
      'isPaid': debt.isPaid ? 1 : 0,
      'notes': null,
    });
  }

  @override
  Future<void> markAsPaid(int debtId) async {
    await _db.updateDebt({
      'id': debtId,
      'isPaid': 1,
    });
  }

  @override
  Future<void> deleteDebt(int debtId) async {
    await _db.deleteDebt(debtId);
  }

  @override
  Stream<List<Debt>> watchClientDebts(int clientId) async* {
    yield await getClientDebts(clientId);
  }

  Future<Debt> _mapToDebt(Map<String, dynamic> map) async {
    final payments = await _db.getPaymentsByDebt(map['id']);
    final paymentList = payments.map((p) => Payment(
      id: p['id'] as int,
      debtId: p['debtId'] as int,
      amount: (p['amount'] as num).toDouble(),
      method: PaymentMethod.fromString(p['paymentMethod'] as String),
      date: DateTime.parse(p['date'] as String),
      notes: p['notes'] as String?,
    )).toList();

    return Debt(
      id: map['id'] as int,
      clientId: map['clientId'] as int,
      productDescription: map['productDescription'] as String,
      quantity: map['quantity'] as int,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      isPaid: map['isPaid'] == 1,
      payments: paymentList,
    );
  }
}