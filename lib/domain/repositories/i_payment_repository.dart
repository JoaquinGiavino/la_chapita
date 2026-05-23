import '../entities/payment.dart';

abstract interface class IPaymentRepository {
  Future<List<Payment>> getPaymentsByDebt(int debtId);
  Future<double> getTotalPaidAmount(int debtId);
  Future<int> registerPayment(Payment payment);
  Future<void> deletePayment(int paymentId);
}