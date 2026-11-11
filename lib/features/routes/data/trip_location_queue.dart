import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:rodantex_app/features/routes/data/models/trip_location.dart';

/// Cola local de ubicaciones pendientes de enviar.
class TripLocationQueue {
  TripLocationQueue(this._preferences);
  final SharedPreferences _preferences;
  static const _key = 'pending_trip_locations';

  /// Agrega una ubicación para reintentarla cuando haya red.
  Future<void> add(String tripId, TripLocation location) async {
    final entries = _read();
    entries.add({'tripId': tripId, 'location': location.toJson()});
    await _save(entries);
  }

  /// Lee todas las ubicaciones pendientes.
  List<Map<String, dynamic>> read() => _read();

  /// Reemplaza la cola después de un intento de envío.
  Future<void> replace(List<Map<String, dynamic>> entries) => _save(entries);

  List<Map<String, dynamic>> _read() {
    final raw = _preferences.getString(_key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    return decoded is List
        ? decoded
              .whereType<Map>()
              .map((item) => item.cast<String, dynamic>())
              .toList()
        : [];
  }

  Future<void> _save(List<Map<String, dynamic>> entries) =>
      _preferences.setString(_key, jsonEncode(entries));
}
