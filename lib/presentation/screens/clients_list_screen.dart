// presentation/screens/clients_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_formatter.dart';
import '../providers/client_provider.dart';
import '../widgets/brand_header.dart';
import '../widgets/client_tile.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/empty_state.dart';
import 'client_detail_screen.dart';
import 'add_client_screen.dart';

enum ClientFilter { all, withDebt, overdue, upToDate }

extension ClientFilterLabel on ClientFilter {
  String get label => switch (this) {
        ClientFilter.all => 'Todos',
        ClientFilter.withDebt => 'Con deuda',
        ClientFilter.overdue => 'Vencida +30d',
        ClientFilter.upToDate => 'Al día',
      };
}

class ClientsListScreen extends ConsumerStatefulWidget {
  const ClientsListScreen({super.key, this.initialFilter = ClientFilter.all});
  final ClientFilter initialFilter;

  @override
  ConsumerState<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends ConsumerState<ClientsListScreen> {
  late ClientFilter _filter;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.trim()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(clientsProvider);
    ref.invalidate(clientDebtSummariesProvider);
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: TextField(
              controller: _searchCtrl,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o teléfono...',
                prefixIcon: Icon(PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular)),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _searchCtrl.clear,
                      )
                    : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ClientFilter.values
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: f.label,
                            isSelected: _filter == f,
                            onTap: () => setState(() => _filter = f),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.vanilla,
              backgroundColor: AppColors.blackSurface,
              child: _ClientsList(query: _query, filter: _filter),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddClientScreen()),
          );
          await _refresh();
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.isSelected, required this.onTap});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.vanilla.withOpacity(0.15) : AppColors.blackElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.vanilla.withOpacity(0.5) : AppColors.white.withOpacity(0.12),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? AppColors.vanilla : AppColors.grey,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _ClientsList extends ConsumerWidget {
  const _ClientsList({required this.query, required this.filter});
  final String query;
  final ClientFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(clientDebtSummariesProvider);
    return summariesAsync.when(
      loading: () => const Padding(padding: EdgeInsets.all(20), child: ShimmerLoading()),
      error: (e, _) => Center(child: Text('Error: $e', style: AppTypography.bodySmall)),
      data: (summaries) {
        var list = summaries.where((s) {
          if (query.isNotEmpty) {
            final q = query.toLowerCase();
            if (!s.client.name.toLowerCase().contains(q) && !s.client.phone.contains(q)) return false;
          }
          return switch (filter) {
            ClientFilter.all => true,
            ClientFilter.withDebt => s.pendingAmount > 0,
            ClientFilter.overdue => s.lastDebtDate != null &&
                DateFormatter.debtAgeStatus(s.lastDebtDate!) != DebtAgeStatus.ok,
            ClientFilter.upToDate => s.pendingAmount == 0,
          };
        }).toList();

        if (list.isEmpty) {
          return EmptyState(
            icon: PhosphorIcons.userCircle(PhosphorIconsStyle.regular),
            title: query.isNotEmpty ? 'Sin resultados para "$query"' : 'No hay clientes aquí',
            subtitle: query.isNotEmpty ? null : 'Probá con otro filtro',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: list.length,
          itemBuilder: (context, i) => ClientTile(
            summary: list[i],
            animationDelay: Duration(milliseconds: 40 * i),
            onTap: () => Navigator.of(context).push(
              _fade(ClientDetailScreen(clientId: list[i].client.id)),
            ),
          ),
        );
      },
    );
  }
}

PageRoute<T> _fade<T>(Widget page) => PageRouteBuilder(
      pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: page),
      transitionDuration: const Duration(milliseconds: 300),
    );