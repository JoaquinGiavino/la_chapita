import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/brand_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/alert_banner.dart';
import '../widgets/client_tile.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/empty_state.dart';
import 'clients_list_screen.dart';
import 'client_detail_screen.dart';
import 'add_client_screen.dart';
import 'add_debt_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardProvider);
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Column(
        children: [
          BrandHeader(
            showSubtitle: true,
            trailing: IconButton(
              icon: Icon(PhosphorIcons.users(PhosphorIconsStyle.regular),
                  color: AppColors.vanilla),
              tooltip: 'Ver todos los clientes',
              onPressed: () => Navigator.of(context)
                  .push(_fade(const ClientsListScreen())),
            ),
          ),
          Expanded(
            child: dashAsync.when(
              loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: ShimmerLoading(itemCount: 6)),
              error: (e, _) => _ErrorView(message: e.toString()),
              data: (summary) => _Body(summary: summary),
            ),
          ),
        ],
      ),
      floatingActionButton: const _Fab(),
    );
  }
}

// ── Body ──────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatsRow(summary: summary),
          const SizedBox(height: 24),
          if (summary.hasAlerts) ...[
            _AlertsSection(summary: summary),
            const SizedBox(height: 24),
          ],
          _RecentSection(summary: summary),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── Stats ─────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final alertCount =
        summary.criticalDebtsCount + summary.warningDebtsCount;
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Deudores',
            value: summary.activeDebtorsCount.toString(),
            icon: PhosphorIcons.users(PhosphorIconsStyle.regular),
            animationDelay: Duration.zero,
            onTap: () => Navigator.of(context)
                .push(_fade(const ClientsListScreen())),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'Pendiente',
            value: CurrencyFormatter.compact(summary.totalPendingAmount),
            icon: PhosphorIcons.currencyDollar(PhosphorIconsStyle.regular),
            animationDelay: const Duration(milliseconds: 100),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'Alertas',
            value: alertCount.toString(),
            icon: PhosphorIcons.bell(PhosphorIconsStyle.regular),
            subtitle: summary.criticalDebtsCount > 0
                ? '${summary.criticalDebtsCount} críticas'
                : null,
            animationDelay: const Duration(milliseconds: 200),
            variant: summary.criticalDebtsCount > 0
                ? StatCardVariant.critical
                : summary.warningDebtsCount > 0
                    ? StatCardVariant.warning
                    : StatCardVariant.normal,
          ),
        ),
      ],
    );
  }
}

// ── Alertas ───────────────────────────────────────────

class _AlertsSection extends StatelessWidget {
  const _AlertsSection({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alertas',
            style:
                AppTypography.headlineMediumOnDark.copyWith(fontSize: 18)),
        const SizedBox(height: 12),
        if (summary.hasCriticalAlerts)
          AlertBanner(
            message:
                '⚠️ Tenés ${summary.criticalDebtsCount} deuda${summary.criticalDebtsCount > 1 ? 's' : ''} con más de 60 días sin pagar',
            severity: AlertSeverity.critical,
            onTap: () => Navigator.of(context).push(
                _fade(const ClientsListScreen(
                    initialFilter: ClientFilter.overdue))),
          ),
        if (summary.hasCriticalAlerts && summary.hasWarningAlerts)
          const SizedBox(height: 8),
        if (summary.hasWarningAlerts)
          AlertBanner(
            message:
                '${summary.warningDebtsCount} deuda${summary.warningDebtsCount > 1 ? 's' : ''} entre 30 y 60 días sin pagar',
            severity: AlertSeverity.warning,
            onTap: () => Navigator.of(context).push(
                _fade(const ClientsListScreen(
                    initialFilter: ClientFilter.overdue))),
          ),
      ],
    );
  }
}

// ── Últimos deudores ──────────────────────────────────

class _RecentSection extends StatelessWidget {
  const _RecentSection({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Últimos Deudores',
                style: AppTypography.headlineMediumOnDark
                    .copyWith(fontSize: 18)),
            TextButton(
              onPressed: () => Navigator.of(context)
                  .push(_fade(const ClientsListScreen())),
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (summary.recentClients.isEmpty)
          EmptyState(
            icon: PhosphorIcons.userPlus(PhosphorIconsStyle.regular),
            title: 'Sin deudores aún',
            subtitle: 'Usá el botón + para agregar tu primer cliente',
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: summary.recentClients.length,
            itemBuilder: (context, i) {
              final s = summary.recentClients[i];
              return ClientTile(
                summary: s,
                animationDelay: Duration(milliseconds: 50 * i),
                onTap: () => Navigator.of(context).push(
                    _fade(ClientDetailScreen(clientId: s.client.id))),
              );
            },
          ),
      ],
    );
  }
}

// ── FAB con menú ──────────────────────────────────────

class _Fab extends StatefulWidget {
  const _Fab();

  @override
  State<_Fab> createState() => _FabState();
}

class _FabState extends State<_Fab> with SingleTickerProviderStateMixin {
  bool _open = false;
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_open) ...[
          _FabItem(
            label: 'Nuevo Cliente',
            icon: PhosphorIcons.userPlus(PhosphorIconsStyle.regular),
            onTap: () {
              _toggle();
              Navigator.of(context)
                  .push(_slideUp(const AddClientScreen()));
            },
          ),
          const SizedBox(height: 8),
          _FabItem(
            label: 'Nueva Deuda',
            icon: PhosphorIcons.receipt(PhosphorIconsStyle.regular),
            onTap: () {
              _toggle();
              Navigator.of(context).push(_slideUp(const AddDebtScreen()));
            },
          ),
          const SizedBox(height: 12),
        ],
        FloatingActionButton(
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _open ? 0.125 : 0,
            duration: const Duration(milliseconds: 250),
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        ),
      ],
    );
  }
}

class _FabItem extends StatelessWidget {
  const _FabItem(
      {required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.blackSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.vanilla.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.vanilla, size: 18),
            const SizedBox(width: 10),
            Text(label,
                style: AppTypography.labelLarge
                    .copyWith(color: AppColors.vanilla)),
          ],
        ),
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text('Error al cargar el dashboard',
              style: AppTypography.titleMediumOnDark),
          const SizedBox(height: 8),
          Text(message, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}

// ── Helpers de navegación ─────────────────────────────

PageRoute<T> _fade<T>(Widget page) => PageRouteBuilder(
      pageBuilder: (_, a, __) =>
          FadeTransition(opacity: a, child: page),
      transitionDuration: const Duration(milliseconds: 300),
    );

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