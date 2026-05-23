// presentation/screens/add_debt_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/debt.dart';
import '../providers/client_provider.dart';
import '../providers/debt_provider.dart';
import '../widgets/brand_header.dart';
import '../widgets/gradient_button.dart';
import '../providers/database_provider.dart';

class AddDebtScreen extends ConsumerStatefulWidget {
  const AddDebtScreen({super.key, this.preselectedClientId});
  final int? preselectedClientId;

  @override
  ConsumerState<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends ConsumerState<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  Client? _selectedClient;
  DateTime _debtDate = DateTime.now();
  bool _isSaving = false;
  final List<_ProductRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = _fmt(_debtDate);
    _addRow();
    if (widget.preselectedClientId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final c = await ref.read(clientRepositoryProvider).getClientById(widget.preselectedClientId!);
        if (mounted && c != null) setState(() => _selectedClient = c);
      });
    }
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _notesCtrl.dispose();
    for (final r in _rows) r.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _addRow() => setState(() => _rows.add(_ProductRow()));

  void _removeRow(int i) {
    if (_rows.length <= 1) return;
    setState(() {
      _rows[i].dispose();
      _rows.removeAt(i);
    });
  }

  double get _total => _rows.fold(0, (s, r) => s + r.subtotal);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _debtDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.vanilla,
            onPrimary: AppColors.black,
            surface: AppColors.blackSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() { _debtDate = picked; _dateCtrl.text = _fmt(picked); });
  }

  Future<void> _save() async {
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccioná un cliente')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El total debe ser mayor a cero')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      for (final row in _rows) {
        final debt = Debt.create(
          clientId: _selectedClient!.id,
          productDescription: row.descCtrl.text.trim(),
          quantity: int.tryParse(row.qtyCtrl.text) ?? 1,
          unitPrice: double.tryParse(row.priceCtrl.text.replaceAll(',', '.')) ?? 0,
          date: _debtDate,
        );
        await ref.read(debtsByClientProvider(_selectedClient!.id).notifier).addDebt(debt);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deuda de ${CurrencyFormatter.format(_total)} registrada para ${_selectedClient!.name}')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Column(
        children: [
          BrandHeader(
            trailing: IconButton(
              icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.regular), color: AppColors.vanilla),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text('Nueva Deuda', style: AppTypography.headlineMediumOnDark),
                  const SizedBox(height: 24),

                  Text('Cliente', style: AppTypography.labelLarge.copyWith(color: AppColors.vanilla)),
                  const SizedBox(height: 8),
                  _ClientDropdown(
                    selected: _selectedClient,
                    onChanged: (c) => setState(() => _selectedClient = c),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Productos', style: AppTypography.labelLarge.copyWith(color: AppColors.vanilla)),
                      TextButton.icon(
                        onPressed: _addRow,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._rows.asMap().entries.map((e) => _ProductRowWidget(
                        row: e.value,
                        canDelete: _rows.length > 1,
                        onDelete: () => _removeRow(e.key),
                        onChanged: () => setState(() {}),
                      )),

                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.vanilla.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.vanilla.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: AppTypography.titleMedium.copyWith(color: AppColors.vanilla)),
                        Text(
                          CurrencyFormatter.format(_total),
                          style: AppTypography.amountMedium.copyWith(color: AppColors.vanilla),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text('Fecha de la deuda', style: AppTypography.labelLarge.copyWith(color: AppColors.vanilla)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _dateCtrl,
                    readOnly: true,
                    onTap: _pickDate,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.white),
                    decoration: InputDecoration(
                      suffixIcon: Icon(PhosphorIcons.calendar(PhosphorIconsStyle.regular), color: AppColors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.white),
                    decoration: InputDecoration(
                      labelText: 'Notas (opcional)',
                      prefixIcon: Icon(PhosphorIcons.note(PhosphorIconsStyle.regular)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  GradientButton(
                    label: 'Guardar Deuda',
                    icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.regular),
                    width: double.infinity,
                    isLoading: _isSaving,
                    onPressed: _save,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientDropdown extends ConsumerWidget {
  const _ClientDropdown({required this.selected, required this.onChanged});
  final Client? selected;
  final ValueChanged<Client?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsProvider);
    return clientsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error: $e', style: AppTypography.bodySmall),
      data: (clients) => DropdownButtonFormField<Client>(
        value: selected,
        hint: const Text('Seleccioná un cliente'),
        dropdownColor: AppColors.blackSurface,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(PhosphorIcons.user(PhosphorIconsStyle.regular)),
        ),
        items: clients
            .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
            .toList(),
        onChanged: onChanged,
        validator: (_) => selected == null ? 'Seleccioná un cliente' : null,
      ),
    );
  }
}

class _ProductRow {
  final descCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '1');
  final priceCtrl = TextEditingController();

  double get subtotal {
    final qty = int.tryParse(qtyCtrl.text) ?? 0;
    final price = double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0;
    return qty * price;
  }

  void dispose() {
    descCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

class _ProductRowWidget extends StatelessWidget {
  const _ProductRowWidget({
    required this.row,
    required this.canDelete,
    required this.onDelete,
    required this.onChanged,
  });
  final _ProductRow row;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blackSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: row.descCtrl,
                  onChanged: (_) => onChanged(),
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.white),
                  decoration: const InputDecoration(
                    labelText: 'Descripción del producto',
                    hintText: 'Ej: Jean azul talle 42',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
              ),
              if (canDelete) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    PhosphorIcons.trash(PhosphorIconsStyle.regular),
                    color: AppColors.error,
                    size: 18,
                  ),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 80,
                child: TextFormField(
                  controller: row.qtyCtrl,
                  onChanged: (_) => onChanged(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.white),
                  decoration: const InputDecoration(
                    labelText: 'Cant.',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Inválido';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: row.priceCtrl,
                  onChanged: (_) => onChanged(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.white),
                  decoration: const InputDecoration(
                    labelText: 'Precio unit.',
                    prefixText: '\$ ',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  validator: (v) {
                    final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                    if (n == null || n <= 0) return 'Inválido';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Subtotal', style: AppTypography.labelSmall),
                  Text(
                    CurrencyFormatter.format(row.subtotal),
                    style: AppTypography.amountSmall.copyWith(color: AppColors.vanilla),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}