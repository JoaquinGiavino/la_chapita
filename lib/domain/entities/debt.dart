import 'payment.dart';

class Debt {
  const Debt({
    required this.id,
    required this.clientId,
    required this.productDescription,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.date,
    required this.isPaid,
    this.payments = const [],
  });

  final int id;
  final int clientId;
  final String productDescription;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final DateTime date;
  final bool isPaid;
  final List<Payment> payments;

  double get paidAmount =>
      payments.fold(0.0, (sum, p) => sum + p.amount);

  double get pendingAmount =>
      (totalAmount - paidAmount).clamp(0.0, double.infinity);

  bool get isFullyPaid => pendingAmount <= 0.005;

  double get paymentProgress =>
      totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;

  DebtStatus get status {
    if (isFullyPaid) return DebtStatus.paid;
    if (paidAmount > 0) return DebtStatus.partial;
    return DebtStatus.pending;
  }

  factory Debt.create({
    required int clientId,
    required String productDescription,
    required int quantity,
    required double unitPrice,
    DateTime? date,
  }) =>
      Debt(
        id: 0,
        clientId: clientId,
        productDescription: productDescription,
        quantity: quantity,
        unitPrice: unitPrice,
        totalAmount: quantity * unitPrice,
        date: date ?? DateTime.now(),
        isPaid: false,
      );

  Debt copyWith({
    int? id,
    int? clientId,
    String? productDescription,
    int? quantity,
    double? unitPrice,
    double? totalAmount,
    DateTime? date,
    bool? isPaid,
    List<Payment>? payments,
  }) =>
      Debt(
        id: id ?? this.id,
        clientId: clientId ?? this.clientId,
        productDescription: productDescription ?? this.productDescription,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        totalAmount: totalAmount ?? this.totalAmount,
        date: date ?? this.date,
        isPaid: isPaid ?? this.isPaid,
        payments: payments ?? this.payments,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Debt && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

enum DebtStatus { pending, partial, paid }