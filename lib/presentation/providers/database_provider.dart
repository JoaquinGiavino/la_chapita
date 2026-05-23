import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database_helper.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/debt_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../domain/repositories/i_client_repository.dart';
import '../../domain/repositories/i_debt_repository.dart';
import '../../domain/repositories/i_payment_repository.dart';

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final clientRepositoryProvider = Provider<IClientRepository>((ref) {
  return ClientRepository();
});

final debtRepositoryProvider = Provider<IDebtRepository>((ref) {
  return DebtRepository();
});

final paymentRepositoryProvider = Provider<IPaymentRepository>((ref) {
  return PaymentRepository();
});