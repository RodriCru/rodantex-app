/// Proveedor disponible para un servicio de mantenimiento.
class MaintenanceSupplier {
  const MaintenanceSupplier({required this.id, required this.name});

  /// Convierte el DTO de proveedor al dato mínimo de selección.
  factory MaintenanceSupplier.fromJson(Map<String, dynamic> json) =>
      MaintenanceSupplier(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Proveedor',
      );

  /// UUID del proveedor.
  final String id;

  /// Nombre que se muestra en el formulario.
  final String name;
}
