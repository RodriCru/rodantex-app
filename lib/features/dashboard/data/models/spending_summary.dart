class SpendingSummary {
  const SpendingSummary({
    required this.amount,
    required this.previousAmount,
    required this.changePercent,
    required this.trend,
  });

  factory SpendingSummary.fromJson(Map<String, dynamic> json) =>
      SpendingSummary(
        // amount/previousAmount vienen como num (int o double) → double.
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        previousAmount: (json['previousAmount'] as num?)?.toDouble() ?? 0,
        // Puede ser null → null. No lo forzamos a 0 para no falsear el dato.
        changePercent: (json['changePercent'] as num?)?.toDouble(),
        trend: json['trend'] as String? ?? 'FLAT',
      );

  final double amount;
  final double previousAmount;
  final double? changePercent; // null si no hay periodo previo
  final String trend;          // "UP" | "DOWN" | "FLAT"

  bool get isUp => trend == 'UP';
  bool get isDown => trend == 'DOWN';
  bool get isFlat => trend == 'FLAT';
}