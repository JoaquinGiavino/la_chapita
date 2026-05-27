// presentation/screens/sales_report_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/database/database_helper.dart';
import '../../domain/entities/sale.dart';
import '../widgets/brand_header.dart';
import '../widgets/gradient_button.dart';

class SalesReportScreen extends ConsumerStatefulWidget {
  const SalesReportScreen({super.key});

  @override
  ConsumerState<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends ConsumerState<SalesReportScreen> {
  DateTime _selectedMonth = DateTime.now();
  List<Sale> _sales = [];
  bool _loading = true;
  double _totalTransferencia = 0;
  double _totalVisaDebito = 0;
  double _totalVisaCredito = 0;
  double _totalMastercardDebito = 0;
  double _totalMastercardCredito = 0;
  double _totalFavacard = 0;
  double _totalGeneral = 0;

  final List<String> _paymentMethods = const [
    'transferencia',
    'visa_debito',
    'visa_credito',
    'mastercard_debito',
    'mastercard_credito',
    'favacard',
  ];

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _loading = true);
    
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
    
    final from = firstDay.toIso8601String();
    final to = lastDay.toIso8601String();
    
    final salesMaps = await DatabaseHelper.instance.getSalesByDateRange(from, to);
    
    final filteredSales = salesMaps.where((map) {
      final method = map['paymentMethod'] as String?;
      return method != null && _paymentMethods.contains(method);
    }).toList();
    
    final sales = <Sale>[];
    for (final map in filteredSales) {
      String? clientName;
      final clientId = map['clientId'] as int?;
      if (clientId != null) {
        final clientMap = await DatabaseHelper.instance.getClientById(clientId);
        clientName = clientMap?['name'] as String?;
      }
      sales.add(Sale.fromMap(map, clientName: clientName));
    }
    
    double totalTransferencia = 0;
    double totalVisaDebito = 0;
    double totalVisaCredito = 0;
    double totalMastercardDebito = 0;
    double totalMastercardCredito = 0;
    double totalFavacard = 0;
    
    for (final sale in sales) {
      switch (sale.paymentMethod) {
        case 'transferencia':
          totalTransferencia += sale.paidAmount;
          break;
        case 'visa_debito':
          totalVisaDebito += sale.paidAmount;
          break;
        case 'visa_credito':
          totalVisaCredito += sale.paidAmount;
          break;
        case 'mastercard_debito':
          totalMastercardDebito += sale.paidAmount;
          break;
        case 'mastercard_credito':
          totalMastercardCredito += sale.paidAmount;
          break;
        case 'favacard':
          totalFavacard += sale.paidAmount;
          break;
      }
    }
    
    setState(() {
      _sales = sales;
      _totalTransferencia = totalTransferencia;
      _totalVisaDebito = totalVisaDebito;
      _totalVisaCredito = totalVisaCredito;
      _totalMastercardDebito = totalMastercardDebito;
      _totalMastercardCredito = totalMastercardCredito;
      _totalFavacard = totalFavacard;
      _totalGeneral = totalTransferencia + totalVisaDebito + totalVisaCredito + 
                      totalMastercardDebito + totalMastercardCredito + totalFavacard;
      _loading = false;
    });
  }

  Future<void> _changeMonth(int offset) async {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset, 1);
    });
    await _loadSales();
  }

  Future<void> _selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2024),
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
        _selectedMonth = DateTime(picked.year, picked.month, 1);
      });
      await _loadSales();
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthFormatter = DateFormat('MMMM yyyy', 'es_AR');
    
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Column(
        children: [
          BrandHeader(
            showSubtitle: false,
            trailing: IconButton(
              icon: Icon(Icons.close, color: AppColors.vanilla),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reporte de Ventas',
                    style: AppTypography.headlineMediumOnDark,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ventas con tarjeta y transferencia',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.grey),
                  ),
                  const SizedBox(height: 24),
                  
                  _MonthSelector(
                    monthText: monthFormatter.format(_selectedMonth),
                    onPrevious: () => _changeMonth(-1),
                    onNext: () => _changeMonth(1),
                    onSelect: _selectMonth,
                  ),
                  const SizedBox(height: 24),
                  
                  if (!_loading) ...[
                    _SummaryCard(
                      transferencia: _totalTransferencia,
                      visaDebito: _totalVisaDebito,
                      visaCredito: _totalVisaCredito,
                      mastercardDebito: _totalMastercardDebito,
                      mastercardCredito: _totalMastercardCredito,
                      favacard: _totalFavacard,
                      total: _totalGeneral,
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_sales.isEmpty)
                    const EmptyStateReport(
                      icon: Icons.receipt_long,
                      title: 'No hay ventas',
                      subtitle: 'No se encontraron ventas con tarjeta o transferencia en este mes',
                    )
                  else
                    _SalesTable(sales: _sales),
                  
                  const SizedBox(height: 40),
                  
                  GradientButton(
                    label: 'Cerrar',
                    icon: Icons.close,
                    width: double.infinity,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.monthText,
    required this.onPrevious,
    required this.onNext,
    required this.onSelect,
  });
  final String monthText;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.blackSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.vanilla),
            onPressed: onPrevious,
          ),
          Expanded(
            child: GestureDetector(
              onTap: onSelect,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.vanilla.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    monthText,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.vanilla,
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.vanilla),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.transferencia,
    required this.visaDebito,
    required this.visaCredito,
    required this.mastercardDebito,
    required this.mastercardCredito,
    required this.favacard,
    required this.total,
  });
  final double transferencia;
  final double visaDebito;
  final double visaCredito;
  final double mastercardDebito;
  final double mastercardCredito;
  final double favacard;
  final double total;

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
          Text('Resumen del mes', style: AppTypography.titleMedium.copyWith(color: AppColors.vanilla)),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Transferencia', amount: transferencia, icon: '📱'),
          const SizedBox(height: 8),
          _SummaryRow(label: 'Visa Débito', amount: visaDebito, icon: '💳'),
          const SizedBox(height: 8),
          _SummaryRow(label: 'Visa Crédito', amount: visaCredito, icon: '💳'),
          const SizedBox(height: 8),
          _SummaryRow(label: 'Mastercard Débito', amount: mastercardDebito, icon: '💳'),
          const SizedBox(height: 8),
          _SummaryRow(label: 'Mastercard Crédito', amount: mastercardCredito, icon: '💳'),
          const SizedBox(height: 8),
          _SummaryRow(label: 'Favacard', amount: favacard, icon: '🏪'),
          Divider(color: AppColors.white.withOpacity(0.1), height: 20),
          _SummaryRow(label: 'TOTAL', amount: total, isTotal: true),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.amount,
    this.icon,
    this.isTotal = false,
  });
  final String label;
  final double amount;
  final String? icon;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Text(icon!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: isTotal 
                  ? AppTypography.titleSmall.copyWith(color: AppColors.vanilla)
                  : AppTypography.bodyMedium.copyWith(color: AppColors.white),
            ),
          ],
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: isTotal
              ? AppTypography.amountMedium.copyWith(color: AppColors.vanilla)
              : AppTypography.amountSmall.copyWith(color: AppColors.vanilla),
        ),
      ],
    );
  }
}

class _SalesTable extends StatelessWidget {
  const _SalesTable({required this.sales});
  final List<Sale> sales;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blackSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white.withOpacity(0.08)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.resolveWith(
            (_) => AppColors.vanilla.withOpacity(0.1),
          ),
          dataRowColor: WidgetStateProperty.resolveWith(
            (_) => AppColors.blackSurface,
          ),
          border: TableBorder.all(
            color: AppColors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          columnSpacing: 16,
          headingTextStyle: AppTypography.labelSmall.copyWith(color: AppColors.vanilla),
          dataTextStyle: AppTypography.bodySmall.copyWith(color: AppColors.white),
          columns: const [
            DataColumn(label: Text('Fecha')),
            DataColumn(label: Text('Producto')),
            DataColumn(label: Text('Monto')),
            DataColumn(label: Text('Método')),
          ],
          rows: sales.map((sale) => DataRow(
            cells: [
              DataCell(Text(DateFormatter.format(sale.date))),
              DataCell(Text('${sale.quantity}x ${sale.productDescription}', overflow: TextOverflow.ellipsis)),
              DataCell(Text(CurrencyFormatter.format(sale.paidAmount))),
              DataCell(Text(_methodLabel(sale.paymentMethod ?? ''))),
            ],
          )).toList(),
        ),
      ),
    );
  }

  String _methodLabel(String method) {
    switch (method) {
      case 'transferencia': return 'Transferencia';
      case 'visa_debito': return 'Visa Débito';
      case 'visa_credito': return 'Visa Crédito';
      case 'mastercard_debito': return 'Mastercard Débito';
      case 'mastercard_credito': return 'Mastercard Crédito';
      case 'favacard': return 'Favacard';
      default: return method;
    }
  }
}

class EmptyStateReport extends StatelessWidget {
  const EmptyStateReport({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.blackSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.vanilla.withOpacity(0.5), size: 48),
          const SizedBox(height: 16),
          Text(title, style: AppTypography.headlineSmall.copyWith(color: AppColors.white)),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTypography.bodyMediumOnDark, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}