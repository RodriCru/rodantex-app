/// Aseguradora disponible para vincular a los datos del vehículo.
class InsuranceSupplier {
  const InsuranceSupplier({required this.id, required this.name});

  /// Convierte el DTO de proveedor al dato mínimo que requiere el selector.
  factory InsuranceSupplier.fromJson(Map<String, dynamic> json) =>
      InsuranceSupplier(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Aseguradora',
      );

  /// UUID que se guarda como `insuranceSupplierId`.
  final String id;

  /// Nombre visible en el selector.
  final String name;
}
