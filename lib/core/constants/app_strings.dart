abstract final class AppStrings {
  static const String appName = 'La Chapita';
  static const String tagline = 'Gestión de deudores';

  // Dashboard
  static const String activeDebtors = 'Deudores Activos';
  static const String pendingAmount = 'Monto Pendiente';
  static const String alerts = 'Alertas';
  static const String latestDebtors = 'Últimos Deudores';

  // Clientes
  static const String newClient = 'Nuevo Cliente';
  static const String editClient = 'Editar Cliente';
  static const String deleteClient = 'Eliminar Cliente';

  // Acciones
  static const String save = 'Guardar';
  static const String cancel = 'Cancelar';
  static const String confirm = 'Confirmar';
  static const String delete = 'Eliminar';

  // Errores
  static const String fieldRequired = 'Este campo es requerido';
  static const String invalidPhone = 'Solo dígitos, mínimo 8';
  static const String invalidName = 'Mínimo 3 caracteres';
  static const String invalidAmount = 'Ingresá un monto válido mayor a 0';
  static const String amountExceedsPending = 'No puede superar el pendiente';

  // Confirmaciones
  static const String confirmDeleteClient =
      '¿Estás seguro de eliminar este cliente? Esta acción no se puede deshacer.';
  static const String confirmDeleteDebt =
      '¿Eliminar esta deuda? Los pagos asociados también se eliminarán.';
}