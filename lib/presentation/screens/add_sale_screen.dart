// presentation/screens/add_sale_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/database/database_helper.dart';
import '../../domain/entities/sale.dart';
import '../../domain/enums/payment_method_sale.dart';
import '../providers/client_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/sale_provider.dart';
import '../widgets/brand_header.dart';
import '../widgets/gradient_button.dart';

class AddSaleScreen extends ConsumerStatefulWidget {
  const AddSaleScreen({super.key});

  @override
  ConsumerState<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends ConsumerState<AddSaleScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de los campos principales
  final _descCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();

  // Estado del pago
  SalePaymentMethod _method = SalePaymentMethod.cash;
  bool _paidFull = true;
  final _paidAmountCtrl = TextEditingController();

  // Estado del cliente (solo si no pagó todo)
  bool _hasClient = false;
  int? _selectedClientId;
  List<Map<String, dynamic>> _clients = [];

  DateTime _saleDate = DateTime.now();
  final _dateCtrl = TextEditingController();

  bool _saving = false;

  // ── Computed ──────────────────────────────────────────
  double get _unitPrice =>
      double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;

  double get _quantity => double.tryParse(_qtyCtrl.text) ?? 1;

  double get _totalAmount => _quantity * _unitPrice;

  double get _paidAmount {
    if (_paidFull) return _totalAmount;
    return double.tryParse(_paidAmountCtrl.text.replaceAll(',', '.')) ?? 0;
  }

  double get _pendingAmount =>
      (_totalAmount - _paidAmount).clamp(0.0, double.infinity);

  bool get _isFullyPaid => _pendingAmount <= 0.005;

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = _formatDate(_saleDate);
    _loadClients();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _paidAmountCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    final list = await DatabaseHelper.instance.getActiveClients();
    if (mounted) setState(() => _clients = list);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _saleDate,
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
    if (picked != null) {
      setState(() {
        _saleDate = picked;
        _dateCtrl.text = _formatDate(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_totalAmount <= 0) {
      _showSnack('El total debe ser mayor a 0', isError: true);
      return;
    }

    // Si no pagó todo, necesita un cliente
    if (!_isFullyPaid && !_hasClient) {
      _showSnack('Seleccioná un cliente para registrar la deuda', isError: true);
      return;
    }
    if (!_isFullyPaid && _selectedClientId == null) {
      _showSnack('Seleccioná un cliente de la lista', isError: true);
      return;
    }

    setState(() => _saving = true);

    try {
      // ── Caso 1: Pago total al contado ─────────────────
      if (_isFullyPaid) {
        final sale = Sale(
          id: 0,
          date: _saleDate,
          productDescription: _descCtrl.text.trim(),
          quantity: _quantity.toInt(),
          unitPrice: _unitPrice,
          totalAmount: _totalAmount,
          paidAmount: _totalAmount,
          pendingAmount: 0,
          isFullyPaid: true,
          paymentMethod: _method.dbValue,
          clientId: null,
          debtId: null,
        );
        await ref.read(salesProvider.notifier).addSale(sale);
        _showSnack('Venta registrada ✅');
      }
      // ── Caso 2: Con deuda (parcial o sin pago) ────────
      else {
        final clientId = _selectedClientId!;
        final now = _saleDate.toIso8601String();

        // 2a. Crear la deuda en la tabla debts
        final debtMap = {
          'clientId': clientId,
          'productDescription': _descCtrl.text.trim(),
          'quantity': _quantity.toInt(),
          'unitPrice': _unitPrice,
          'totalAmount': _totalAmount,
          'date': now,
          'isPaid': 0,
          'notes': null,
        };
        final debtId = await DatabaseHelper.instance.insertDebt(debtMap);

        // 2b. Si pagó algo parcial, registrar el pago en payments
        if (_paidAmount > 0) {
          final paymentMap = {
            'debtId': debtId,
            'amount': _paidAmount,
            'paymentMethod': _method.dbValue,
            'date': now,
            'notes': 'Pago inicial al momento de la venta',
          };
          await DatabaseHelper.instance.insertPayment(paymentMap);
        }

        // 2c. Crear la venta en sales (vinculada a la deuda)
        final sale = Sale(
          id: 0,
          date: _saleDate,
          productDescription: _descCtrl.text.trim(),
          quantity: _quantity.toInt(),
          unitPrice: _unitPrice,
          totalAmount: _totalAmount,
          paidAmount: _paidAmount,
          pendingAmount: _pendingAmount,
          isFullyPaid: false,
          paymentMethod: _paidAmount > 0 ? _method.dbValue : null,
          clientId: clientId,
          debtId: debtId,
        );
        await ref.read(salesProvider.notifier).addSale(sale);

        // 2d. Refrescar providers de deudas y clientes
        ref.invalidate(debtsByClientProvider(clientId));
        ref.invalidate(clientDebtSummariesProvider);
        ref.invalidate(clientsProvider);

        _showSnack('Venta registrada con deuda de '
            '${CurrencyFormatter.format(_pendingAmount)} ✅');
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Column(
        children: [
          BrandHeader(
            trailing: IconButton(
              icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.regular),
                  color: AppColors.vanilla),
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
                  Text('Nueva Venta',
                      style: AppTypography.headlineMediumOnDark),
                  const SizedBox(height: 24),

                  // ── Producto ──────────────────────────
                  _SectionTitle('Producto'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.white),
                    decoration: InputDecoration(
                      labelText: 'Descripción',
                      hintText: 'Ej: Jean azul talle 42',
                      prefixIcon: Icon(PhosphorIcons.tag(
                          PhosphorIconsStyle.regular)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'La descripción es requerida'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: TextFormField(
                          controller: _qtyCtrl,
                          onChanged: (_) => setState(() {}),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.white),
                          decoration: const InputDecoration(
                            labelText: 'Cantidad',
                            isDense: true,
                          ),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n <= 0) return 'Inválido';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _priceCtrl,
                          onChanged: (_) => setState(() {}),
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[\d,.]'))
                          ],
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.white),
                          decoration: const InputDecoration(
                            labelText: 'Precio unitario',
                            prefixText: '\$ ',
                            isDense: true,
                          ),
                          validator: (v) {
                            final n = double.tryParse(
                                v?.replaceAll(',', '.') ?? '');
                            if (n == null || n <= 0) return 'Inválido';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  if (_totalAmount > 0) ...[
                    const SizedBox(height: 16),
                    _TotalRow(
                      total: _totalAmount,
                      paid: _paidAmount,
                      pending: _pendingAmount,
                    ),
                  ],

                  const SizedBox(height: 24),

                  _SectionTitle('Pago'),
                  const SizedBox(height: 12),

                  _ToggleRow(
                    label: 'Pagó el total en este momento',
                    value: _paidFull,
                    onChanged: (v) => setState(() {
                      _paidFull = v;
                      if (v) {
                        _hasClient = false;
                        _selectedClientId = null;
                        _paidAmountCtrl.clear();
                      }
                    }),
                  ),
                  const SizedBox(height: 12),

                  if (!_paidFull) ...[
                    TextFormField(
                      controller: _paidAmountCtrl,
                      onChanged: (_) => setState(() {}),
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[\d,.]'))
                      ],
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.white),
                      decoration: const InputDecoration(
                        labelText:
                            'Monto pagado ahora (0 si no pagó nada)',
                        prefixText: '\$ ',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = double.tryParse(v.replaceAll(',', '.'));
                        if (n == null || n < 0) return 'Inválido';
                        if (n > _totalAmount) {
                          return 'No puede superar el total '
                              '(${CurrencyFormatter.format(_totalAmount)})';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _ToggleRow(
                      label: 'Asociar a un cliente existente',
                      value: _hasClient,
                      onChanged: (v) => setState(() {
                        _hasClient = v;
                        if (!v) _selectedClientId = null;
                      }),
                    ),
                    if (_hasClient) ...[
                      const SizedBox(height: 12),
                      _ClientDropdown(
                        clients: _clients,
                        selectedClientId: _selectedClientId,
                        onChanged: (id) =>
                            setState(() => _selectedClientId = id),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],

                  if (_paidFull || _paidAmount > 0) ...[
                    _SectionTitle('Método de pago'),
                    const SizedBox(height: 12),
                    _PaymentMethodGrid(
                      selected: _method,
                      onChanged: (m) => setState(() => _method = m),
                    ),
                    const SizedBox(height: 24),
                  ],

                  _SectionTitle('Fecha'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _dateCtrl,
                    readOnly: true,
                    onTap: _pickDate,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.white),
                    decoration: InputDecoration(
                      suffixIcon: Icon(
                          PhosphorIcons.calendar(
                              PhosphorIconsStyle.regular),
                          color: AppColors.grey),
                    ),
                  ),
                  const SizedBox(height: 32),

                  GradientButton(
                    label: 'Registrar Venta',
                    icon: PhosphorIcons.checkCircle(
                        PhosphorIconsStyle.regular),
                    width: double.infinity,
                    isLoading: _saving,
                    onPressed: _saving ? null : _save,
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

// ══════════════════════════════════════════════════════════
// WIDGETS INTERNOS DE LA PANTALLA
// ══════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelLarge.copyWith(color: AppColors.vanilla),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.blackSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.white)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.vanilla,
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.total,
    required this.paid,
    required this.pending,
  });
  final double total;
  final double paid;
  final double pending;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.vanilla.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.vanilla.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _Num(label: 'Total', value: total, color: AppColors.white),
          const SizedBox(width: 20),
          _Num(label: 'Pagado', value: paid, color: AppColors.success),
          const SizedBox(width: 20),
          _Num(
              label: 'Resta',
              value: pending,
              color: pending > 0 ? AppColors.error : AppColors.success),
        ],
      ),
    );
  }
}

class _Num extends StatelessWidget {
  const _Num(
      {required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall),
        Text(CurrencyFormatter.format(value),
            style: AppTypography.amountSmall.copyWith(color: color)),
      ],
    );
  }
}

class _ClientDropdown extends StatelessWidget {
  const _ClientDropdown({
    required this.clients,
    required this.selectedClientId,
    required this.onChanged,
  });
  final List<Map<String, dynamic>> clients;
  final int? selectedClientId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (clients.isEmpty) {
      return Text(
        'No hay clientes registrados. Creá uno primero.',
        style: AppTypography.bodySmall.copyWith(color: AppColors.error),
      );
    }
    return DropdownButtonFormField<int>(
      value: selectedClientId,
      hint: const Text('Seleccioná un cliente'),
      dropdownColor: AppColors.blackSurface,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(PhosphorIcons.user(PhosphorIconsStyle.regular)),
      ),
      items: clients.map((c) => DropdownMenuItem<int>(
        value: c['id'] as int,
        child: Text(
          '${c['name']}  ·  ${c['phone']}',
          overflow: TextOverflow.ellipsis,
        ),
      )).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Seleccioná un cliente' : null,
    );
  }
}

class _PaymentMethodGrid extends StatelessWidget {
  const _PaymentMethodGrid({
    required this.selected,
    required this.onChanged,
  });
  final SalePaymentMethod selected;
  final ValueChanged<SalePaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final methods = SalePaymentMethod.values;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: methods.map((m) {
        final sel = m == selected;
        return GestureDetector(
          onTap: () => onChanged(m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: sel
                  ? AppColors.vanilla.withOpacity(0.15)
                  : AppColors.blackSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: sel ? AppColors.vanilla : AppColors.white.withOpacity(0.12),
                width: sel ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(m.icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  m.displayName,
                  style: AppTypography.labelSmall.copyWith(
                    color: sel ? AppColors.vanilla : AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}