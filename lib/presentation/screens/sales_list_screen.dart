// presentation/screens/sales_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/database/database_helper.dart';
import '../../domain/entities/sale.dart';
import '../providers/sale_provider.dart';
import '../widgets/brand_header.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_loading.dart';
import 'add_sale_screen.dart';

class SalesListScreen extends ConsumerStatefulWidget {
  const SalesListScreen({super.key});

  @override
  ConsumerState<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends ConsumerState<SalesListScreen> {
  SalesPeriod _period = SalesPeriod.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(salesProvider.notifier).load(_period);
    });
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesProvider);
    final statsAsync = ref.watch(salesStatsProvider);

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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ventas', style: AppTypography.headlineMediumOnDark),
                const SizedBox(height: 16),
                _PeriodStatsRow(statsAsync: statsAsync),
                const SizedBox(height: 16),
                _PeriodChips(
                  selected: _period,
                  onChanged: (p) {
                    setState(() => _period = p);
                    ref.read(salesProvider.notifier).load(p);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: salesAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(20), child: ShimmerLoading()),
              error: (e, _) => Center(child: Text('Error: $e', style: AppTypography.bodySmall)),
              data: (sales) {
                if (sales.isEmpty) {
                  return EmptyState(
                    icon: PhosphorIcons.shoppingBag(PhosphorIconsStyle.regular),
                    title: 'Sin ventas en este período',
                    subtitle: 'Registrá tu primera venta con el botón +',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: sales.length,
                  itemBuilder: (context, i) => _SaleTile(
                    sale: sales[i],
                    index: i,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(_slideUp(const AddSaleScreen()))
            .then((_) => ref.read(salesProvider.notifier).load(_period)),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _PeriodStatsRow extends ConsumerWidget {
  const _PeriodStatsRow({required this.statsAsync});
  final AsyncValue<SalesDashboardStats> statsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return statsAsync.when(
      loading: () => const SizedBox(height: 48),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) => Row(
        children: [
          _StatPill(label: 'Hoy', value: stats.todayAmount, count: stats.todayCount),
          const SizedBox(width: 10),
          _StatPill(label: 'Semana', value: stats.weekAmount, count: stats.weekCount),
          const SizedBox(width: 10),
          _StatPill(label: 'Mes', value: stats.monthAmount, count: stats.monthCount),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value, required this.count});
  final String label;
  final double value;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.blackSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.labelSmall),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.compact(value),
              style: AppTypography.amountSmall.copyWith(color: AppColors.vanilla),
              overflow: TextOverflow.ellipsis,
            ),
            Text('$count venta${count == 1 ? '' : 's'}', style: AppTypography.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _PeriodChips extends StatelessWidget {
  const _PeriodChips({required this.selected, required this.onChanged});
  final SalesPeriod selected;
  final ValueChanged<SalesPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = {
      SalesPeriod.today: 'Hoy',
      SalesPeriod.week: 'Esta semana',
      SalesPeriod.month: 'Este mes',
      SalesPeriod.all: 'Todas',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: SalesPeriod.values.map((p) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected == p ? AppColors.vanilla.withOpacity(0.15) : AppColors.blackElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected == p ? AppColors.vanilla.withOpacity(0.5) : AppColors.white.withOpacity(0.12)),
              ),
              child: Text(
                labels[p]!,
                style: AppTypography.labelSmall.copyWith(
                  color: selected == p ? AppColors.vanilla : AppColors.grey,
                  fontWeight: selected == p ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }
}

class _SaleTile extends ConsumerStatefulWidget {
  const _SaleTile({required this.sale, required this.index});
  final Sale sale;
  final int index;

  @override
  ConsumerState<_SaleTile> createState() => _SaleTileState();
}

class _SaleTileState extends ConsumerState<_SaleTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;
    final typeColor = switch (sale.type) {
      SaleType.cash => AppColors.success,
      SaleType.partialDebt => AppColors.warning,
      SaleType.fullDebt => AppColors.error,
    };
    final typeLabel = switch (sale.type) {
      SaleType.cash => 'Contado',
      SaleType.partialDebt => 'Parcial',
      SaleType.fullDebt => 'Deuda',
    };

    return Dismissible(
      key: Key('sale_${sale.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      confirmDismiss: (_) => _confirmDelete(context, sale.id),
      onDismissed: (_) {
        ref.read(salesProvider.notifier).deleteSale(sale.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venta eliminada')),
        );
      },
      child: Animate(
        delay: Duration(milliseconds: 40 * widget.index),
        effects: const [
          FadeEffect(duration: Duration(milliseconds: 300)),
          SlideEffect(begin: Offset(0.04, 0), end: Offset.zero, duration: Duration(milliseconds: 300)),
        ],
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.blackElevated : AppColors.blackSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hovered ? AppColors.vanilla.withOpacity(0.2) : AppColors.white.withOpacity(0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${sale.quantity}x ${sale.productDescription}',
                        style: AppTypography.titleSmallOnDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TypeChip(label: typeLabel, color: typeColor),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _AmountCol(label: 'Total', value: sale.totalAmount, color: AppColors.grey),
                    const SizedBox(width: 20),
                    _AmountCol(label: 'Cobrado', value: sale.paidAmount, color: AppColors.success),
                    if (sale.pendingAmount > 0) ...[
                      const SizedBox(width: 20),
                      _AmountCol(label: 'Resta', value: sale.pendingAmount, color: AppColors.error),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(PhosphorIcons.calendar(PhosphorIconsStyle.regular), size: 12, color: AppColors.grey),
                    const SizedBox(width: 4),
                    Text(DateFormatter.format(sale.date), style: AppTypography.bodySmall),
                    if (sale.clientName != null) ...[
                      const SizedBox(width: 12),
                      Icon(PhosphorIcons.user(PhosphorIconsStyle.regular), size: 12, color: AppColors.grey),
                      const SizedBox(width: 4),
                      Flexible(child: Text(sale.clientName!, style: AppTypography.bodySmall, overflow: TextOverflow.ellipsis)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, int saleId) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar venta'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.color});
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
      child: Text(label, style: AppTypography.labelSmall.copyWith(color: color)),
    );
  }
}

class _AmountCol extends StatelessWidget {
  const _AmountCol({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall),
        const SizedBox(height: 2),
        Text(CurrencyFormatter.format(value), style: AppTypography.amountSmall.copyWith(color: color)),
      ],
    );
  }
}

PageRoute<T> _slideUp<T>(Widget page) => PageRouteBuilder(
      pageBuilder: (_, a, __) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
        child: page,
      ),
      transitionDuration: const Duration(milliseconds: 350),
    );