import '../enums/payment_method.dart';

class Payment {
  const Payment({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.method,
    required this.date,
    this.notes,
  });

  final int id;
  final int debtId;
  final double amount;
  final PaymentMethod method;
  final DateTime date;
  final String? notes;

  factory Payment.create({
    required int debtId,
    required double amount,
    required PaymentMethod method,
    DateTime? date,
    String? notes,
  }) =>
      Payment(
        id: 0,
        debtId: debtId,
        amount: amount,
        method: method,
        date: date ?? DateTime.now(),
        notes: notes,
      );

  Payment copyWith({
    int? id,
    int? debtId,
    double? amount,
    PaymentMethod? method,
    DateTime? date,
    String? notes,
  }) =>
      Payment(
        id: id ?? this.id,
        debtId: debtId ?? this.debtId,
        amount: amount ?? this.amount,
        method: method ?? this.method,
        date: date ?? this.date,
        notes: notes ?? this.notes,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Payment && other.id == id;

  @override
  int get hashCode => id.hashCode;
}