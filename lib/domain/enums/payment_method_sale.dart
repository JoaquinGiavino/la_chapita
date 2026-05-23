// domain/enums/payment_method_sale.dart
// Separado del PaymentMethod de deudas porque ventas tiene
// más métodos (Visa, Mastercard, Favacard)

enum SalePaymentMethod {
  cash,
  transfer,
  visa,
  mastercard,
  favacard;

  static SalePaymentMethod fromString(String? value) => switch (value) {
        'efectivo' => SalePaymentMethod.cash,
        'transferencia' => SalePaymentMethod.transfer,
        'visa' => SalePaymentMethod.visa,
        'mastercard' => SalePaymentMethod.mastercard,
        'favacard' => SalePaymentMethod.favacard,
        _ => SalePaymentMethod.cash,
      };

  String get dbValue => switch (this) {
        SalePaymentMethod.cash => 'efectivo',
        SalePaymentMethod.transfer => 'transferencia',
        SalePaymentMethod.visa => 'visa',
        SalePaymentMethod.mastercard => 'mastercard',
        SalePaymentMethod.favacard => 'favacard',
      };

  String get displayName => switch (this) {
        SalePaymentMethod.cash => 'Efectivo',
        SalePaymentMethod.transfer => 'Transferencia',
        SalePaymentMethod.visa => 'Visa',
        SalePaymentMethod.mastercard => 'Mastercard',
        SalePaymentMethod.favacard => 'Favacard',
      };

  String get icon => switch (this) {
        SalePaymentMethod.cash => '💵',
        SalePaymentMethod.transfer => '📱',
        SalePaymentMethod.visa => '💳',
        SalePaymentMethod.mastercard => '💳',
        SalePaymentMethod.favacard => '🏪',
      };
}