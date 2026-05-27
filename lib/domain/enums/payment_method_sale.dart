// domain/enums/payment_method_sale.dart

enum SalePaymentMethod {
  cash,
  transfer,
  visaDebito,
  visaCredito,
  mastercardDebito,
  mastercardCredito,
  favacard;

  static SalePaymentMethod fromString(String? value) => switch (value) {
        'efectivo' => SalePaymentMethod.cash,
        'transferencia' => SalePaymentMethod.transfer,
        'visa_debito' => SalePaymentMethod.visaDebito,
        'visa_credito' => SalePaymentMethod.visaCredito,
        'mastercard_debito' => SalePaymentMethod.mastercardDebito,
        'mastercard_credito' => SalePaymentMethod.mastercardCredito,
        'favacard' => SalePaymentMethod.favacard,
        _ => SalePaymentMethod.cash,
      };

  String get dbValue => switch (this) {
        SalePaymentMethod.cash => 'efectivo',
        SalePaymentMethod.transfer => 'transferencia',
        SalePaymentMethod.visaDebito => 'visa_debito',
        SalePaymentMethod.visaCredito => 'visa_credito',
        SalePaymentMethod.mastercardDebito => 'mastercard_debito',
        SalePaymentMethod.mastercardCredito => 'mastercard_credito',
        SalePaymentMethod.favacard => 'favacard',
      };

  String get displayName => switch (this) {
        SalePaymentMethod.cash => 'Efectivo',
        SalePaymentMethod.transfer => 'Transferencia',
        SalePaymentMethod.visaDebito => 'Visa Débito',
        SalePaymentMethod.visaCredito => 'Visa Crédito',
        SalePaymentMethod.mastercardDebito => 'Mastercard Débito',
        SalePaymentMethod.mastercardCredito => 'Mastercard Crédito',
        SalePaymentMethod.favacard => 'Favacard',
      };

  String get icon => switch (this) {
        SalePaymentMethod.cash => '💵',
        SalePaymentMethod.transfer => '📱',
        SalePaymentMethod.visaDebito => '💳',
        SalePaymentMethod.visaCredito => '💳',
        SalePaymentMethod.mastercardDebito => '💳',
        SalePaymentMethod.mastercardCredito => '💳',
        SalePaymentMethod.favacard => '🏪',
      };

  // Para saber si es crédito o débito
  String get cardType => switch (this) {
        SalePaymentMethod.visaDebito => 'débito',
        SalePaymentMethod.visaCredito => 'crédito',
        SalePaymentMethod.mastercardDebito => 'débito',
        SalePaymentMethod.mastercardCredito => 'crédito',
        _ => '',
      };

  // Para saber la red de la tarjeta (Visa, Mastercard, Favacard)
  String get cardNetwork => switch (this) {
        SalePaymentMethod.visaDebito => 'Visa',
        SalePaymentMethod.visaCredito => 'Visa',
        SalePaymentMethod.mastercardDebito => 'Mastercard',
        SalePaymentMethod.mastercardCredito => 'Mastercard',
        SalePaymentMethod.favacard => 'Favacard',
        _ => '',
      };
}