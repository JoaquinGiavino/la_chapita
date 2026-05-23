// domain/entities/sale.dart

class Sale {
  const Sale({
    required this.id,
    required this.date,
    required this.productDescription,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.isFullyPaid,
    this.paymentMethod,
    this.clientId,
    this.clientName,
    this.debtId,
  });

  final int id;
  final DateTime date;
  final String productDescription;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;
  final bool isFullyPaid;
  final String? paymentMethod;   // null si la venta generó deuda sin pago inicial
  final int? clientId;           // null si fue pago al contado sin deuda
  final String? clientName;      // join opcional para mostrar en la UI
  final int? debtId;             // null si fue al contado

  SaleType get type {
    if (debtId != null && paidAmount == 0) return SaleType.fullDebt;
    if (debtId != null && paidAmount > 0) return SaleType.partialDebt;
    return SaleType.cash;
  }

  /// Construye una Sale desde el Map que devuelve sqflite
  factory Sale.fromMap(Map<String, dynamic> map, {String? clientName}) =>
      Sale(
        id: map['id'] as int,
        date: DateTime.parse(map['date'] as String),
        productDescription: map['productDescription'] as String,
        quantity: map['quantity'] as int,
        unitPrice: (map['unitPrice'] as num).toDouble(),
        totalAmount: (map['totalAmount'] as num).toDouble(),
        paidAmount: (map['paidAmount'] as num).toDouble(),
        pendingAmount: (map['pendingAmount'] as num).toDouble(),
        isFullyPaid: (map['isFullyPaid'] as int) == 1,
        paymentMethod: map['paymentMethod'] as String?,
        clientId: map['clientId'] as int?,
        clientName: clientName,
        debtId: map['debtId'] as int?,
      );

  /// Convierte la Sale a Map para insertar en sqflite
  Map<String, dynamic> toMap() => {
        if (id != 0) 'id': id,
        'date': date.toIso8601String(),
        'productDescription': productDescription,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'pendingAmount': pendingAmount,
        'isFullyPaid': isFullyPaid ? 1 : 0,
        'paymentMethod': paymentMethod,
        'clientId': clientId,
        'debtId': debtId,
      };

  Sale copyWith({
    int? id,
    DateTime? date,
    String? productDescription,
    int? quantity,
    double? unitPrice,
    double? totalAmount,
    double? paidAmount,
    double? pendingAmount,
    bool? isFullyPaid,
    String? paymentMethod,
    int? clientId,
    String? clientName,
    int? debtId,
  }) =>
      Sale(
        id: id ?? this.id,
        date: date ?? this.date,
        productDescription: productDescription ?? this.productDescription,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        totalAmount: totalAmount ?? this.totalAmount,
        paidAmount: paidAmount ?? this.paidAmount,
        pendingAmount: pendingAmount ?? this.pendingAmount,
        isFullyPaid: isFullyPaid ?? this.isFullyPaid,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        clientId: clientId ?? this.clientId,
        clientName: clientName ?? this.clientName,
        debtId: debtId ?? this.debtId,
      );
}

enum SaleType {
  cash,         // Pago total al contado, sin deuda
  partialDebt,  // Pagó algo pero quedó con deuda
  fullDebt,     // No pagó nada, todo queda como deuda
}