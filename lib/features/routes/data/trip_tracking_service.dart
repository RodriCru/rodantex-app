import 'dart:async';

import 'package:location/location.dart';

import 'package:rodantex_app/features/routes/data/models/trip.dart';
import 'package:rodantex_app/features/routes/data/models/trip_location.dart';
import 'package:rodantex_app/features/routes/data/routes_repository.dart';
import 'package:rodantex_app/features/routes/data/trip_location_queue.dart';

/// Servicio de captura y envío optimizado de ubicación para el conductor.
class TripTrackingService {
  TripTrackingService({required this.repository, required this.queue});
  final RoutesRepository repository;
  final TripLocationQueue queue;
  final Location _location = Location();
  Timer? _timer;
  String? _tripId;
  bool _sending = false;

  /// Inicia el tracking solo mientras el viaje está en curso.
  Future<void> start(FleetTrip trip) async {
    if (trip.status != TripStatus.inProgress || _tripId == trip.id) return;
    await stop();
    if (!await _prepareLocation()) return;
    _tripId = trip.id;
    await flushQueue();
    await _capture();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _capture());
  }

  /// Detiene el tracking del viaje actual.
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _tripId = null;
  }

  /// Reintenta ubicaciones acumuladas sin conexión.
  Future<void> flushQueue() async {
    final pending = queue.read();
    final remaining = <Map<String, dynamic>>[];
    for (final entry in pending) {
      try {
        await repository.createTripLocation(
          entry['tripId'] as String,
          TripLocation.fromJson(
            (entry['location'] as Map).cast<String, dynamic>(),
          ),
        );
      } catch (_) {
        remaining.add(entry);
      }
    }
    await queue.replace(remaining);
  }

  Future<bool> _prepareLocation() async {
    if (!await _location.serviceEnabled() && !await _location.requestService())
      return false;
    var permission = await _location.hasPermission();
    if (permission == PermissionStatus.denied)
      permission = await _location.requestPermission();
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.grantedLimited)
      return false;
    await _location.enableBackgroundMode(enable: true);
    await _location.changeSettings(
      accuracy: LocationAccuracy.balanced,
      interval: 300000,
      distanceFilter: 100,
    );
    return true;
  }

  Future<void> _capture() async {
    final tripId = _tripId;
    if (tripId == null || _sending) return;
    _sending = true;
    try {
      final data = await _location.getLocation();
      final latitude = data.latitude;
      final longitude = data.longitude;
      if (latitude == null || longitude == null) return;
      final location = TripLocation(
        latitude: latitude,
        longitude: longitude,
        recordedAt: DateTime.now().toUtc(),
      );
      try {
        await repository.createTripLocation(tripId, location);
        await flushQueue();
      } catch (_) {
        await queue.add(tripId, location);
      }
    } finally {
      _sending = false;
    }
  }

  /// Libera temporizadores y suscripción de conectividad.
  Future<void> dispose() => stop();
}
