import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/debt.dart';

class DebtCard extends StatelessWidget {
  const DebtCard({
    super.key,
    required this.debt,
    this.onRegisterPayment,
  });

  final Debt debt;
  final VoidCallback? onRegisterPayment;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (debt.status) {
      DebtStatus.paid => AppColors.success,
      DebtStatus.partial => AppColors.warning,
      DebtStatus.pending => AppColors.error,
    };
    final statusLabel = switch (debt.status) {
      DebtStatus.paid => 'Pagado',
      DebtStatus.partial => 'Parcial',
      DebtStatus.pending => 'Pendiente',
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blackSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  '${debt.quantity}x ${debt.productDescription}',
                  style: AppTypography.titleSmallOnDark,
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          // Montos
          Row(
            children: [
              _AmountItem(label: 'Total', value: CurrencyFormatter.format(debt.totalAmount), color: AppColors.grey),
              const SizedBox(width: 16),
              _AmountItem(label: 'Pagado', value: CurrencyFormatter.format(debt.paidAmount), color: AppColors.success),
              const SizedBox(width: 16),
              _AmountItem(label: 'Pendiente', value: CurrencyFormatter.format(debt.pendingAmount), color: AppColors.vanilla),
            ],
          ),
          const SizedBox(height: 12),
          // Barra progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: debt.paymentProgress,
              minHeight: 6,
              backgroundColor: AppColors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(
                debt.isFullyPaid ? AppColors.success : AppColors.vanilla,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(DateFormatter.relative(debt.date), style: AppTypography.bodySmall),
          // Botón pago
          if (!debt.isFullyPaid && onRegisterPayment != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRegisterPayment,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                child: const Text('Registrar Pago'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: AppTypography.labelSmall.copyWith(color: color)),
    );
  }
}

class _AmountItem extends StatelessWidget {
  const _AmountItem({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall),
        const SizedBox(height: 2),
        Text(value,
            style: AppTypography.amountSmall.copyWith(color: color)),
      ],
    );
  }
}