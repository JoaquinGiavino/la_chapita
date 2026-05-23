import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/payment.dart';
import '../providers/client_provider.dart';
import '../providers/debt_provider.dart';
import '../widgets/brand_header.dart';
import '../widgets/debt_card.dart';
import '../widgets/payment_history_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/gradient_button.dart';
import 'add_debt_screen.dart';
import 'add_client_screen.dart';
import 'register_payment_screen.dart';

class ClientDetailScreen extends ConsumerWidget {
  const ClientDetailScreen({super.key, required this.clientId});
  final int clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientByIdProvider(clientId));
    final debtsAsync = ref.watch(debtsByClientProvider(clientId));

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Column(
        children: [
          BrandHeader(
            trailing: IconButton(
              icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.regular),
                  color: AppColors.vanilla),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: clientAsync.when(
              loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: ShimmerLoading()),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: AppTypography.bodySmall)),
              data: (client) {
                if (client == null) {
                  return EmptyState(
                    icon: PhosphorIcons.userCircleMinus(
                        PhosphorIconsStyle.regular),
                    title: 'Cliente no encontrado',
                  );
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ClientHeader(
                          client: client, debtsAsync: debtsAsync),
                      const SizedBox(height: 28),
                      _DebtsSection(
                          clientId: clientId, debtsAsync: debtsAsync),
                      const SizedBox(height: 28),
                      _ActionButtons(
                          clientId: clientId, client: client),
                      const SizedBox(height: 60),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header del cliente ────────────────────────────────

class _ClientHeader extends StatelessWidget {
  const _ClientHeader(
      {required this.client, required this.debtsAsync});
  final Client client;
  final AsyncValue<List<Debt>> debtsAsync;

  @override
  Widget build(BuildContext context) {
    final debts = debtsAsync.value ?? [];
    final totalPending =
        debts.fold<double>(0, (s, d) => s + d.pendingAmount);

    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.vanilla.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              client.name[0].toUpperCase(),
              style: AppTypography.headlineLargeOnDark
                  .copyWith(fontSize: 28),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(client.name,
                  style: AppTypography.headlineMediumOnDark),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                      PhosphorIcons.phone(PhosphorIconsStyle.regular),
                      size: 14,
                      color: AppColors.grey),
                  const SizedBox(width: 4),
                  Text(client.phone,
                      style: AppTypography.bodySmall),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Pendiente', style: AppTypography.labelSmall),
            Text(
              CurrencyFormatter.format(totalPending),
              style: AppTypography.amountMedium.copyWith(
                color: totalPending > 0
                    ? AppColors.vanilla
                    : AppColors.success,
              ),
            ),
          ],
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms);
  }
}

// ── Sección de deudas ─────────────────────────────────

class _DebtsSection extends ConsumerWidget {
  const _DebtsSection(
      {required this.clientId, required this.debtsAsync});
  final int clientId;
  final AsyncValue<List<Debt>> debtsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Deudas',
                style: AppTypography.headlineMediumOnDark
                    .copyWith(fontSize: 18)),
            TextButton.icon(
              onPressed: () => Navigator.of(context)
                  .push(_slideUp(AddDebtScreen(
                      preselectedClientId: clientId))),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Agregar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        debtsAsync.when(
          loading: () => const ShimmerLoading(itemCount: 3),
          error: (e, _) =>
              Text('Error: $e', style: AppTypography.bodySmall),
          data: (debts) {
            if (debts.isEmpty) {
              return EmptyState(
                icon: PhosphorIcons.receipt(
                    PhosphorIconsStyle.regular),
                title: 'Sin deudas registradas',
                subtitle:
                    'Este cliente no tiene deudas activas',
              );
            }

            final pending =
                debts.where((d) => !d.isFullyPaid).toList();
            final paid =
                debts.where((d) => d.isFullyPaid).toList();

            final allPayments = debts
                .expand((d) => d.payments)
                .toList()
              ..sort(
                  (a, b) => b.date.compareTo(a.date));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...pending.asMap().entries.map((e) =>
                    _DismissibleDebt(
                      debt: e.value,
                      clientId: clientId,
                      index: e.key,
                    )),

                if (paid.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Pagadas (${paid.length})',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.success),
                  ),
                  const SizedBox(height: 8),
                  ...paid.map((d) => DebtCard(debt: d)),
                ],

                if (allPayments.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Historial de Pagos',
                      style: AppTypography.headlineMediumOnDark
                          .copyWith(fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.blackSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      children: allPayments
                          .map((p) => Column(
                                children: [
                                  PaymentHistoryTile(payment: p),
                                  if (p != allPayments.last)
                                    Divider(
                                        color: AppColors.white
                                            .withOpacity(0.06)),
                                ],
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DismissibleDebt extends ConsumerWidget {
  const _DismissibleDebt(
      {required this.debt, required this.clientId, required this.index});
  final Debt debt;
  final int clientId;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key('debt_${debt.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error),
      ),
      confirmDismiss: (_) => ConfirmDialog.show(
        context,
        title: 'Eliminar deuda',
        content:
            '¿Eliminar este producto? Los pagos asociados también se eliminarán.',
        confirmLabel: 'Eliminar',
        isDestructive: true,
      ),
      onDismissed: (_) {
        ref
            .read(debtsByClientProvider(clientId).notifier)
            .deleteDebt(debt.id);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Deuda eliminada')));
      },
      child: DebtCard(
        debt: debt,
        onRegisterPayment: () => Navigator.of(context).push(_slideUp(
            RegisterPaymentScreen(debt: debt, clientId: clientId))),
      )
          .animate(
              delay: Duration(milliseconds: 60 * index))
          .fadeIn(duration: 300.ms),
    );
  }
}

// ── Botones de acción ─────────────────────────────────

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons(
      {required this.clientId, required this.client});
  final int clientId;
  final Client client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        GradientButton(
          label: 'Agregar Nueva Deuda',
          icon: PhosphorIcons.plusCircle(PhosphorIconsStyle.regular),
          width: double.infinity,
          onPressed: () => Navigator.of(context)
              .push(_slideUp(AddDebtScreen(
                  preselectedClientId: clientId))),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context)
                .push(_slideUp(AddClientScreen(
                    clientToEdit: client))),
            icon: Icon(
                PhosphorIcons.pencilSimple(
                    PhosphorIconsStyle.regular),
                size: 18),
            label: const Text('Editar Cliente'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => _confirmDelete(context, ref),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar Cliente'),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Eliminar cliente',
      content:
          '¿Estás seguro de eliminar a ${client.name}? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDestructive: true,
    );
    if (ok && context.mounted) {
      ref.read(clientsProvider.notifier).deleteClient(clientId);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${client.name} eliminado')));
    }
  }
}

PageRoute<T> _slideUp<T>(Widget page) => PageRouteBuilder(
      pageBuilder: (_, a, __) => SlideTransition(
        position: Tween<Offset>(
                begin: const Offset(0, 1), end: Offset.zero)
            .animate(
                CurvedAnimation(parent: a, curve: Curves.easeOut)),
        child: page,
      ),
      transitionDuration: const Duration(milliseconds: 350),
    );