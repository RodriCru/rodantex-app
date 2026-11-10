/// Llanta montada en un vehículo que puede incluirse en una inspección.
class VehicleInspectionTire {
  const VehicleInspectionTire({
    required this.id,
    this.currentPosition,
    this.brand,
    this.model,
    this.width,
    this.profile,
    this.rimDiameter,
    this.treadDepth,
    this.referenceDepthMm,
  });

  /// Convierte el DTO `GetTireDto` al conjunto usado en el formulario.
  factory VehicleInspectionTire.fromJson(Map<String, dynamic> json) =>
      VehicleInspectionTire(
        id: json['id'] as String? ?? '',
        currentPosition: json['currentPosition'] as String?,
        brand: json['brand'] as String?,
        model: json['model'] as String?,
        width: (json['width'] as num?)?.toInt(),
        profile: (json['profile'] as num?)?.toInt(),
        rimDiameter: (json['rimDiameter'] as num?)?.toInt(),
        treadDepth: (json['treadDepth'] as num?)?.toDouble(),
        referenceDepthMm: (json['referenceDepthMm'] as num?)?.toDouble(),
      );

  /// UUID de la llanta y posición actual en el vehículo.
  final String id;
  final String? currentPosition;

  /// Identificación y medida del neumático.
  final String? brand;
  final String? model;
  final int? width;
  final int? profile;
  final int? rimDiameter;

  /// Profundidad actual y de referencia, cuando el backend las informa.
  final double? treadDepth;
  final double? referenceDepthMm;

  /// Nombre corto que identifica una llanta en la inspección.
  String get displayName {
    final size = [
      width,
      profile,
      rimDiameter,
    ].whereType<int>().map((number) => number.toString()).join('/');
    return [
      currentPosition,
      brand,
      model,
      if (size.isNotEmpty) size,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' · ');
  }
}
