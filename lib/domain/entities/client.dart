class Client {
  const Client({
    required this.id,
    required this.name,
    required this.phone,
    required this.createdAt,
    required this.isActive,
  });

  final int id;
  final String name;
  final String phone;
  final DateTime createdAt;
  final bool isActive;

  factory Client.create({required String name, required String phone}) =>
      Client(
        id: 0,
        name: name,
        phone: phone,
        createdAt: DateTime.now(),
        isActive: true,
      );

  Client copyWith({
    int? id,
    String? name,
    String? phone,
    DateTime? createdAt,
    bool? isActive,
  }) =>
      Client(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        createdAt: createdAt ?? this.createdAt,
        isActive: isActive ?? this.isActive,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Client && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Client(id: $id, name: $name)';
}

class ClientDebtSummary {
  const ClientDebtSummary({
    required this.client,
    required this.totalDebt,
    required this.pendingAmount,
    required this.productCount,
    required this.lastDebtDate,
  });

  final Client client;
  final double totalDebt;
  final double pendingAmount;
  final int productCount;
  final DateTime? lastDebtDate;

  bool get hasDebt => pendingAmount > 0;
}