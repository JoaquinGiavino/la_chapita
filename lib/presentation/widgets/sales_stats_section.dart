import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/database/database_helper.dart';
import '../providers/sale_provider.dart';
import '../screens/sales_list_screen.dart';

class SalesStatsSection extends ConsumerWidget {
  const SalesStatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(salesStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ventas',
                style: AppTypography.headlineMediumOnDark.copyWith(fontSize: 22)),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                _fade(const SalesListScreen()),
              ),
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        statsAsync.when(
          loading: () => const _StatsPlaceholder(),
          error: (e, _) => Text('Error: $e', style: AppTypography.bodySmall),
          data: (stats) => _StatsCards(stats: stats),
        ),
      ],
    );
  }
}

class _StatsCards extends StatelessWidget {
  const _StatsCards({required this.stats});
  final SalesDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SalesCard(
            label: 'Hoy',
            amount: stats.todayAmount,
            count: stats.todayCount,
            icon: PhosphorIcons.sun(PhosphorIconsStyle.regular),
            delay: Duration.zero,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SalesCard(
            label: 'Semana',
            amount: stats.weekAmount,
            count: stats.weekCount,
            icon: PhosphorIcons.calendarBlank(PhosphorIconsStyle.regular),
            delay: const Duration(milliseconds: 100),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SalesCard(
            label: 'Mes',
            amount: stats.monthAmount,
            count: stats.monthCount,
            icon: PhosphorIcons.chartLine(PhosphorIconsStyle.regular),
            delay: const Duration(milliseconds: 200),
          ),
        ),
      ],
    );
  }
}

class _SalesCard extends StatelessWidget {
  const _SalesCard({
    required this.label,
    required this.amount,
    required this.count,
    required this.icon,
    required this.delay,
  });
  final String label;
  final double amount;
  final int count;
  final IconData icon;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Animate(
      delay: delay,
      effects: const [
        FadeEffect(duration: Duration(milliseconds: 400)),
        SlideEffect(begin: Offset(0, 0.1), end: Offset.zero, duration: Duration(milliseconds: 400)),
      ],
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.blackSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.vanilla, size: 20),
                const SizedBox(width: 8),
                Text(label, style: AppTypography.titleSmall.copyWith(color: AppColors.vanilla)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              CurrencyFormatter.format(amount),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.vanilla,  // ← Color vainilla para el monto
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$count venta${count == 1 ? '' : 's'}',
              style: AppTypography.bodySmall.copyWith(color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsPlaceholder extends StatelessWidget {
  const _StatsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (i) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 2 ? 12 : 0),
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.blackSurface,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

PageRoute<T> _fade<T>(Widget page) => PageRouteBuilder(
      pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: page),
      transitionDuration: const Duration(milliseconds: 300),
    );