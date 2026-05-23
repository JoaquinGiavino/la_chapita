// presentation/screens/register_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/payment.dart';
import '../../domain/enums/payment_method.dart';
import '../../domain/entities/sale.dart';
import '../../data/database/database_helper.dart';
import '../providers/debt_provider.dart';
import '../providers/sale_provider.dart';
import '../widgets/gradient_button.dart';

class RegisterPaymentScreen extends ConsumerStatefulWidget {
  const RegisterPaymentScreen({
    super.key,
    required this.debt,
    required this.clientId,
  });

  final Debt debt;
  final int clientId;

  @override
  ConsumerState<RegisterPaymentScreen> createState() =>
      _RegisterPaymentScreenState();
}

class _RegisterPaymentScreenState
    extends ConsumerState<RegisterPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();

  PaymentMethod _selectedMethod = PaymentMethod.cash;
  DateTime _paymentDate = DateTime.now();
  bool _isSaving = false;
  bool _payFullAmount = false;

  double get _pendingAmount => widget.debt.pendingAmount;

  @override
  void initState() {
    super.initState();
    _dateController.text = _formatDate(_paymentDate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
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
        _paymentDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  void _togglePayFull(bool value) {
    setState(() {
      _payFullAmount = value;
      if (value) {
        _amountController.text =
            _pendingAmount.toStringAsFixed(2).replaceAll('.', ',');
      } else {
        _amountController.clear();
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) return;

    setState(() => _isSaving = true);

    try {
      // ── 1. Registrar el pago en la tabla payments (igual que antes) ──
      final payment = Payment.create(
        debtId: widget.debt.id,
        amount: amount,
        method: _selectedMethod,
        date: _paymentDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await ref
          .read(debtsByClientProvider(widget.clientId).notifier)
          .registerPayment(
            payment: payment,
            debtTotalAmount: widget.debt.totalAmount,
            currentPendingAmount: _pendingAmount,
          );

      // ── 2. Registrar el pago como venta en la tabla sales ─────────────
      final saleRepo = ref.read(saleRepositoryProvider);
      final existingSale = await saleRepo.getSaleByDebtId(widget.debt.id);

      if (existingSale != null) {
        // Actualizar la venta existente sumando el pago
        final newPaid = existingSale.paidAmount + amount;
        await saleRepo.updatePaidAmount(
          saleId: existingSale.id,
          newPaidAmount: newPaid,
          totalAmount: widget.debt.totalAmount,
        );
      } else {
        // Crear una nueva venta vinculada a la deuda
        final totalPaidSoFar =
            await DatabaseHelper.instance.getTotalPaidForDebt(widget.debt.id);
        final pending = (widget.debt.totalAmount - totalPaidSoFar)
            .clamp(0.0, double.infinity);

        final newSale = Sale(
          id: 0,
          date: _paymentDate,
          productDescription: widget.debt.productDescription,
          quantity: widget.debt.quantity,
          unitPrice: widget.debt.unitPrice,
          totalAmount: widget.debt.totalAmount,
          paidAmount: totalPaidSoFar,
          pendingAmount: pending,
          isFullyPaid: pending <= 0.005,
          paymentMethod: payment.method.dbValue,
          clientId: widget.clientId,
          debtId: widget.debt.id,
        );
        await saleRepo.createSale(newSale);
      }

      // ── 3. Invalidar el provider de ventas para que el dashboard actualice ──
      ref.invalidate(salesStatsProvider);
      ref.invalidate(salesProvider);

      if (mounted) {
        final isFullyPaid = amount >= _pendingAmount;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFullyPaid
                  ? '✅ Deuda saldada y venta registrada'
                  : 'Pago registrado. Pendiente: ${CurrencyFormatter.format(_pendingAmount - amount)}',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.white),
            ),
            backgroundColor:
                isFullyPaid ? AppColors.success : AppColors.blackSurface,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar pago: $e'),
            backgroundColor: AppColors.error,
          ),
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
      appBar: AppBar(
        title: Text(
          'Registrar Pago',
          style: AppTypography.headlineMediumOnDark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _DebtSummaryCard(debt: widget.debt),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.blackSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pagar monto total pendiente',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.white),
                    ),
                  ),
                  Switch(
                    value: _payFullAmount,
                    onChanged: _togglePayFull,
                    activeColor: AppColors.vanilla,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Monto a pagar',
              style: AppTypography.labelLarge
                  .copyWith(color: AppColors.vanilla),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              enabled: !_payFullAmount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
              ],
              decoration: const InputDecoration(
                hintText: '0,00',
                prefixText: '\$ ',
              ),
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.white),
              validator: (v) {
                final amount =
                    double.tryParse(v?.replaceAll(',', '.') ?? '');
                if (amount == null || amount <= 0) {
                  return 'Ingresá un monto válido mayor a 0';
                }
                if (amount > _pendingAmount + 0.01) {
                  return 'El monto no puede superar el pendiente (${CurrencyFormatter.format(_pendingAmount)})';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            Text(
              'Método de pago',
              style: AppTypography.labelLarge
                  .copyWith(color: AppColors.vanilla),
            ),
            const SizedBox(height: 8),
            _MethodSelector(
              selected: _selectedMethod,
              onChanged: (m) => setState(() => _selectedMethod = m),
            ),
            const SizedBox(height: 16),

            Text(
              'Fecha del pago',
              style: AppTypography.labelLarge
                  .copyWith(color: AppColors.vanilla),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _dateController,
              readOnly: true,
              onTap: _pickDate,
              decoration: InputDecoration(
                suffixIcon: Icon(
                  PhosphorIcons.calendar(PhosphorIconsStyle.regular),
                  color: AppColors.grey,
                ),
              ),
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.white),
            ),
            const SizedBox(height: 16),

            Text(
              'Notas (opcional)',
              style: AppTypography.labelLarge
                  .copyWith(color: AppColors.vanilla),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                  hintText: 'Observaciones del pago...'),
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.white),
            ),
            const SizedBox(height: 32),

            GradientButton(
              label: 'Registrar Pago',
              icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.regular),
              isLoading: _isSaving,
              width: double.infinity,
              onPressed: _isSaving ? null : _save,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DebtSummaryCard extends StatelessWidget {
  const _DebtSummaryCard({required this.debt});
  final Debt debt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blackSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.vanilla.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${debt.quantity}x ${debt.productDescription}',
            style: AppTypography.titleMedium
                .copyWith(color: AppColors.vanilla),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SummaryItem(
                label: 'Total deuda',
                value: CurrencyFormatter.format(debt.totalAmount),
                color: AppColors.grey,
              ),
              const SizedBox(width: 20),
              _SummaryItem(
                label: 'Ya pagado',
                value: CurrencyFormatter.format(debt.paidAmount),
                color: AppColors.success,
              ),
              const SizedBox(width: 20),
              _SummaryItem(
                label: 'Pendiente',
                value: CurrencyFormatter.format(debt.pendingAmount),
                color: AppColors.vanilla,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: debt.paymentProgress,
              minHeight: 6,
              backgroundColor: AppColors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(AppColors.vanilla),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });
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
        Text(
          value,
          style: AppTypography.amountSmall.copyWith(color: color),
        ),
      ],
    );
  }
}

class _MethodSelector extends StatelessWidget {
  const _MethodSelector({
    required this.selected,
    required this.onChanged,
  });
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: PaymentMethod.values.map((method) {
        final isSelected = method == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(method),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.vanilla.withOpacity(0.15)
                    : AppColors.blackSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.vanilla
                      : AppColors.white.withOpacity(0.12),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(method.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(
                    method.displayName,
                    style: AppTypography.labelSmall.copyWith(
                      color: isSelected ? AppColors.vanilla : AppColors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}