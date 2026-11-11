/// Tipo de gasto asociado a un viaje.
enum TripExpenseType {
  fuel('FUEL', 'Combustible'),
  toll('TOLL', 'Caseta'),
  food('FOOD', 'Alimentos'),
  parking('PARKING', 'Estacionamiento'),
  repair('REPAIR', 'Reparación'),
  other('OTHER', 'Otro');

  const TripExpenseType(this.apiValue, this.label);

  /// Valor aceptado por la API.
  final String apiValue;

  /// Texto visible para el usuario.
  final String label;

  /// Convierte el valor de la API y tolera valores futuros.
  static TripExpenseType fromApi(Object? value) =>
      TripExpenseType.values.firstWhere(
        (type) => type.apiValue == value,
        orElse: () => TripExpenseType.other,
      );
}

/// Gasto registrado durante un viaje.
class TripExpense {
  const TripExpense({
    required this.id,
    required this.type,
    required this.amount,
    this.liters,
    this.odometer,
    this.expenseDate,
    this.description,
    this.receiptUrl,
  });

  /// Construye un gasto desde la respuesta de la API.
  factory TripExpense.fromJson(Map<String, dynamic> json) => TripExpense(
    id: json['id'] as String? ?? '',
    type: TripExpenseType.fromApi(json['type']),
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    liters: (json['liters'] as num?)?.toDouble(),
    odometer: (json['odometer'] as num?)?.toDouble(),
    expenseDate: DateTime.tryParse(json['expenseDate'] as String? ?? ''),
    description: json['description'] as String?,
    receiptUrl: json['receiptUrl'] as String?,
  );

  /// Identificador del gasto.
  final String id;
  final TripExpenseType type;
  final double amount;
  final double? liters;
  final double? odometer;
  final DateTime? expenseDate;
  final String? description;
  final String? receiptUrl;
}
