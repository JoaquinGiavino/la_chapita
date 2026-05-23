enum PaymentMethod {
  cash,
  transfer,
  card;

  static PaymentMethod fromString(String value) => switch (value) {
        'efectivo' => PaymentMethod.cash,
        'transferencia' => PaymentMethod.transfer,
        'tarjeta' => PaymentMethod.card,
        _ => PaymentMethod.cash,
      };

  String get dbValue => switch (this) {
        PaymentMethod.cash => 'efectivo',
        PaymentMethod.transfer => 'transferencia',
        PaymentMethod.card => 'tarjeta',
      };

  String get displayName => switch (this) {
        PaymentMethod.cash => 'Efectivo',
        PaymentMethod.transfer => 'Transferencia',
        PaymentMethod.card => 'Tarjeta',
      };

  String get icon => switch (this) {
        PaymentMethod.cash => '💵',
        PaymentMethod.transfer => '📱',
        PaymentMethod.card => '💳',
      };
}