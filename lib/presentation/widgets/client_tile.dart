import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/client.dart';

class ClientTile extends StatefulWidget {
  const ClientTile({
    super.key,
    required this.summary,
    required this.onTap,
    this.animationDelay = Duration.zero,
  });

  final ClientDebtSummary summary;
  final VoidCallback onTap;
  final Duration animationDelay;

  @override
  State<ClientTile> createState() => _ClientTileState();
}

class _ClientTileState extends State<ClientTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.summary.lastDebtDate != null
        ? DateFormatter.debtAgeStatus(widget.summary.lastDebtDate!)
        : DebtAgeStatus.ok;

    final dotColor = switch (status) {
      DebtAgeStatus.ok => AppColors.success,
      DebtAgeStatus.warning => AppColors.warning,
      DebtAgeStatus.critical => AppColors.error,
    };

    return Animate(
      delay: widget.animationDelay,
      effects: const [
        FadeEffect(duration: Duration(milliseconds: 350)),
        SlideEffect(
          begin: Offset(0.05, 0),
          end: Offset.zero,
          duration: Duration(milliseconds: 350),
          curve: Curves.easeOut,
        ),
      ],
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.blackElevated : AppColors.blackSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hovered
                    ? AppColors.vanilla.withOpacity(0.2)
                    : AppColors.white.withOpacity(0.08),
              ),
            ),
            child: Row(
              children: [
                // Indicador de estado
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 14),
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.vanilla.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      widget.summary.client.name[0].toUpperCase(),
                      style: AppTypography.titleMedium.copyWith(
                          color: AppColors.vanilla, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Nombre y teléfono
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.summary.client.name,
                        style: AppTypography.titleSmallOnDark,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(widget.summary.client.phone,
                          style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                // Monto pendiente
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.compact(widget.summary.pendingAmount),
                      style: AppTypography.amountSmall.copyWith(
                        color: widget.summary.pendingAmount > 0
                            ? AppColors.vanilla
                            : AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.summary.productCount > 0
                          ? '${widget.summary.productCount} prod.'
                          : 'Al día',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}