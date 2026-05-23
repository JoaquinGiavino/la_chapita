import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/debt.dart';
import 'client_provider.dart';
import 'debt_provider.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.activeDebtorsCount,
    required this.totalPendingAmount,
    required this.criticalDebtsCount,
    required this.warningDebtsCount,
    required this.recentClients,
    required this.criticalDebts,
    required this.warningDebts,
  });

  final int activeDebtorsCount;
  final double totalPendingAmount;
  final int criticalDebtsCount;
  final int warningDebtsCount;
  final List<ClientDebtSummary> recentClients;
  final List<Debt> criticalDebts;
  final List<Debt> warningDebts;

  bool get hasCriticalAlerts => criticalDebtsCount > 0;
  bool get hasWarningAlerts => warningDebtsCount > 0;
  bool get hasAlerts => hasCriticalAlerts || hasWarningAlerts;

  static const empty = DashboardSummary(
    activeDebtorsCount: 0,
    totalPendingAmount: 0,
    criticalDebtsCount: 0,
    warningDebtsCount: 0,
    recentClients: [],
    criticalDebts: [],
    warningDebts: [],
  );
}

final dashboardProvider = FutureProvider<DashboardSummary>((ref) async {
  final summaries = ref.watch(clientDebtSummariesProvider).value ?? [];
  final critical = ref.watch(oldDebtsProvider(60)).value ?? [];
  final warn30 = ref.watch(oldDebtsProvider(30)).value ?? [];

  final criticalIds = critical.map((d) => d.id).toSet();
  final warning = warn30.where((d) => !criticalIds.contains(d.id)).toList();

  final debtors = summaries.where((s) => s.pendingAmount > 0).toList();
  final total = debtors.fold<double>(0, (s, c) => s + c.pendingAmount);

  return DashboardSummary(
    activeDebtorsCount: debtors.length,
    totalPendingAmount: total,
    criticalDebtsCount: critical.length,
    warningDebtsCount: warning.length,
    recentClients: summaries.take(10).toList(),
    criticalDebts: critical,
    warningDebts: warning,
  );
});