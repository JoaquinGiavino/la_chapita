import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/payment.dart';

class PaymentHistoryTile extends StatelessWidget {
  const PaymentHistoryTile({super.key, required this.payment});
  final Payment payment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(payment.method.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.method.displayName,
                    style: AppTypography.titleSmallOnDark),
                Text(DateFormatter.format(payment.date),
                    style: AppTypography.bodySmall),
                if (payment.notes != null && payment.notes!.isNotEmpty)
                  Text(payment.notes!,
                      style: AppTypography.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.grey)),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(payment.amount),
            style: AppTypography.amountSmall.copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }
}