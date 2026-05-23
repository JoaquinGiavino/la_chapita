import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/client.dart';
import '../providers/client_provider.dart';
import '../widgets/brand_header.dart';
import '../widgets/gradient_button.dart';
import '../widgets/confirm_dialog.dart';

class AddClientScreen extends ConsumerStatefulWidget {
  const AddClientScreen({super.key, this.clientToEdit});
  final Client? clientToEdit;

  @override
  ConsumerState<AddClientScreen> createState() =>
      _AddClientScreenState();
}

class _AddClientScreenState
    extends ConsumerState<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  bool _loading = false;

  bool get _isEditing => widget.clientToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: widget.clientToEdit?.name ?? '');
    _phoneCtrl = TextEditingController(
        text: widget.clientToEdit?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditing
                        ? 'Editar Cliente'
                        : 'Nuevo Cliente',
                    style: AppTypography.headlineMediumOnDark,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isEditing
                        ? 'Modificá los datos del cliente'
                        : 'Completá los datos para registrar al cliente',
                    style: AppTypography.bodyMediumOnDark,
                  ),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    autovalidateMode:
                        AutovalidateMode.onUserInteraction,
                    child: Column(
                      children: [
                        // Campo Nombre
                        TextFormField(
                          controller: _nameCtrl,
                          textCapitalization:
                              TextCapitalization.words,
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.white),
                          decoration: InputDecoration(
                            labelText: 'Nombre completo',
                            hintText: 'Ej: María González',
                            prefixIcon: Icon(PhosphorIcons.user(
                                PhosphorIconsStyle.regular)),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'El nombre es requerido';
                            }
                            if (v.trim().length < 3) {
                              return 'Mínimo 3 caracteres';
                            }
                            if (v.trim().length > 100) {
                              return 'Máximo 100 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Campo Teléfono
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.white),
                          decoration: InputDecoration(
                            labelText: 'Teléfono',
                            hintText: 'Ej: 2236123456',
                            prefixIcon: Icon(PhosphorIcons.phone(
                                PhosphorIconsStyle.regular)),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'El teléfono es requerido';
                            }
                            if (v.trim().length < 8) {
                              return 'Mínimo 8 dígitos';
                            }
                            if (v.trim().length > 15) {
                              return 'Máximo 15 dígitos';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Botones
                  GradientButton(
                    label: _isEditing
                        ? 'Guardar Cambios'
                        : 'Guardar Cliente',
                    icon: PhosphorIcons.checkCircle(
                        PhosphorIconsStyle.regular),
                    width: double.infinity,
                    isLoading: _loading,
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
                  if (_isEditing) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _delete,
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.error),
                        child: const Text('Eliminar Cliente'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_isEditing) {
        final updated = widget.clientToEdit!.copyWith(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        );
        await ref
            .read(clientsProvider.notifier)
            .updateClient(updated);
      } else {
        final client = Client.create(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        );
        await ref
            .read(clientsProvider.notifier)
            .addClient(client);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_isEditing
                ? 'Cliente actualizado'
                : '${_nameCtrl.text.trim()} agregado')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Eliminar cliente',
      content:
          '¿Eliminar a ${widget.clientToEdit!.name}? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDestructive: true,
    );
    if (ok && mounted) {
      await ref
          .read(clientsProvider.notifier)
          .deleteClient(widget.clientToEdit!.id);
      if (mounted) {
        Navigator.of(context)
          ..pop()
          ..pop();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cliente eliminado')));
      }
    }
  }
}