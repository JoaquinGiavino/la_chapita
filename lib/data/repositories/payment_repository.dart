import '../../domain/entities/payment.dart';
import '../../domain/enums/payment_method.dart';
import '../../domain/repositories/i_payment_repository.dart';
import '../database/database_helper.dart';

class PaymentRepository implements IPaymentRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  @override
  Future<List<Payment>> getPaymentsByDebt(int debtId) async {
    final maps = await _db.getPaymentsByDebt(debtId);
    return maps.map((map) => Payment(
      id: map['id'] as int,
      debtId: map['debtId'] as int,
      amount: (map['amount'] as num).toDouble(),
      method: PaymentMethod.fromString(map['paymentMethod'] as String),
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
    )).toList();
  }

  @override
  Future<double> getTotalPaidAmount(int debtId) async {
    return await _db.getTotalPaidForDebt(debtId);
  }

  @override
  Future<int> registerPayment(Payment payment) async {
    return await _db.insertPayment({
      'debtId': payment.debtId,
      'amount': payment.amount,
      'paymentMethod': payment.method.dbValue,
      'date': payment.date.toIso8601String(),
      'notes': payment.notes,
    });
  }

  @override
  Future<void> deletePayment(int paymentId) async {
    await _db.deletePayment(paymentId);
  }
}