import 'package:flutter/material.dart';
import 'package:rodantex_app/core/network/api_exception.dart';
import 'package:rodantex_app/features/routes/data/models/route.dart';
import 'package:rodantex_app/features/routes/data/models/trip.dart';
import 'package:rodantex_app/features/routes/data/routes_repository.dart';

/// Consulta rutas y viajes asignados; no permite crear rutas ni viajes.
class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key, required this.repository});
  final RoutesRepository repository;
  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  late Future<List<FleetRoute>> _routes = widget.repository.listRoutes();
  late Future<List<FleetTrip>> _trips = widget.repository.listTrips();
  void _reload() => setState(() {
    _routes = widget.repository.listRoutes();
    _trips = widget.repository.listTrips();
  });
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Rutas y viajes'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Rutas'),
            Tab(text: 'Mis viajes'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: TabBarView(
          children: [
            _RoutesList(future: _routes, repository: widget.repository),
            _TripsList(future: _trips, repository: widget.repository),
          ],
        ),
      ),
    ),
  );
}

class _RoutesList extends StatelessWidget {
  const _RoutesList({required this.future, required this.repository});
  final Future<List<FleetRoute>> future;
  final RoutesRepository repository;
  @override
  Widget build(BuildContext context) => FutureBuilder<List<FleetRoute>>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done)
        return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return _Error(error: snapshot.error);
      final routes = snapshot.data ?? const <FleetRoute>[];
      if (routes.isEmpty)
        return const Center(child: Text('No hay rutas disponibles.'));
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final route in routes)
            Card(
              child: ListTile(
                title: Text(route.name),
                subtitle: Text(
                  '${route.originName ?? 'Origen'} → ${route.destinationName ?? 'Destino'}\n${route.stops.length} paradas',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => _RouteDialog(route: route),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _RouteDialog extends StatelessWidget {
  const _RouteDialog({required this.route});
  final FleetRoute route;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(route.name),
    content: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(route.description ?? 'Sin descripción'),
          const SizedBox(height: 12),
          Text(
            '${route.originName ?? 'Origen'} → ${route.destinationName ?? 'Destino'}',
          ),
          if (route.estimatedDistanceKm != null)
            Text('Distancia: ${route.estimatedDistanceKm} km'),
          if (route.estimatedDurationMinutes != null)
            Text('Duración: ${route.estimatedDurationMinutes} min'),
          const SizedBox(height: 12),
          for (final stop in route.stops) Text('${stop.order}. ${stop.name}'),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cerrar'),
      ),
    ],
  );
}

class _TripsList extends StatelessWidget {
  const _TripsList({required this.future, required this.repository});
  final Future<List<FleetTrip>> future;
  final RoutesRepository repository;
  @override
  Widget build(BuildContext context) => FutureBuilder<List<FleetTrip>>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done)
        return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return _Error(error: snapshot.error);
      final trips = snapshot.data ?? const <FleetTrip>[];
      if (trips.isEmpty)
        return const Center(child: Text('No tienes viajes asignados.'));
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final trip in trips)
            Card(
              child: ListTile(
                title: Text(trip.vehicleLabel ?? 'Viaje'),
                subtitle: Text(
                  '${trip.originName ?? 'Origen'} → ${trip.destinationName ?? 'Destino'}\n${_status(trip.status)}',
                ),
                isThreeLine: true,
                onTap: () => showDialog(
                  context: context,
                  builder: (_) =>
                      _TripDialog(trip: trip, repository: repository),
                ),
              ),
            ),
        ],
      );
    },
  );
}

String _status(TripStatus status) => switch (status) {
  TripStatus.scheduled => 'Programado',
  TripStatus.inProgress => 'En curso',
  TripStatus.completed => 'Completado',
  TripStatus.canceled => 'Cancelado',
  TripStatus.incident => 'Incidente',
};

class _TripDialog extends StatefulWidget {
  const _TripDialog({required this.trip, required this.repository});
  final FleetTrip trip;
  final RoutesRepository repository;
  @override
  State<_TripDialog> createState() => _TripDialogState();
}

class _TripDialogState extends State<_TripDialog> {
  bool saving = false;
  String? error;
  @override
  Widget build(BuildContext context) {
    final next = switch (widget.trip.status) {
      TripStatus.scheduled => [
        TripStatus.inProgress,
        TripStatus.canceled,
        TripStatus.incident,
      ],
      TripStatus.inProgress => [
        TripStatus.completed,
        TripStatus.canceled,
        TripStatus.incident,
      ],
      TripStatus.incident => [
        TripStatus.inProgress,
        TripStatus.completed,
        TripStatus.canceled,
      ],
      _ => <TripStatus>[],
    };
    return AlertDialog(
      title: const Text('Detalle del viaje'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.trip.originName ?? 'Origen'} → ${widget.trip.destinationName ?? 'Destino'}',
          ),
          Text('Chofer: ${widget.trip.driverName}'),
          Text('Estado: ${_status(widget.trip.status)}'),
          if (widget.trip.notes != null) Text('Notas: ${widget.trip.notes}'),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        for (final status in next)
          TextButton(
            onPressed: saving
                ? null
                : () async {
                    setState(() => saving = true);
                    try {
                      await widget.repository.updateTripStatus(
                        widget.trip.id,
                        status,
                      );
                      if (mounted) Navigator.pop(context);
                    } on ApiException catch (e) {
                      if (mounted)
                        setState(() {
                          error = e.message;
                          saving = false;
                        });
                    }
                  },
            child: Text(_status(status)),
          ),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({this.error});
  final Object? error;
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      error is ApiException
          ? (error as ApiException).message
          : 'No se pudo cargar la información.',
    ),
  );
}
