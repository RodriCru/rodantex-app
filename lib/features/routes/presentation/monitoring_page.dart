import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:rodantex_app/core/network/api_exception.dart';
import 'package:rodantex_app/features/routes/data/models/trip_location.dart';
import 'package:rodantex_app/features/routes/data/routes_repository.dart';

/// Consulta las últimas ubicaciones de vehículos en viajes activos.
class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key, required this.repository});
  final RoutesRepository repository;

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  late Future<List<MonitoredVehicle>> _vehicles = widget.repository
      .listMonitoredVehicles();

  void _reload() =>
      setState(() => _vehicles = widget.repository.listMonitoredVehicles());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Monitoreo de vehículos'),
      actions: [
        IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
      ],
    ),
    body: FutureBuilder<List<MonitoredVehicle>>(
      future: _vehicles,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(
            child: Text(
              snapshot.error is ApiException
                  ? (snapshot.error! as ApiException).message
                  : 'No se pudo cargar el monitoreo.',
            ),
          );
        final vehicles = snapshot.data ?? const <MonitoredVehicle>[];
        if (vehicles.isEmpty)
          return const Center(child: Text('No hay vehículos en monitoreo.'));
        final points = vehicles
            .where((item) => item.latitude != null && item.longitude != null)
            .toList();
        final center = points.isEmpty
            ? const LatLng(19.4326, -99.1332)
            : LatLng(points.first.latitude!, points.first.longitude!);
        return Column(
          children: [
            SizedBox(
              height: 280,
              child: FlutterMap(
                options: MapOptions(initialCenter: center, initialZoom: 10),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.rodantex.rodantex_app',
                  ),
                  MarkerLayer(
                    markers: [
                      for (final item in points)
                        Marker(
                          point: LatLng(item.latitude!, item.longitude!),
                          width: 44,
                          height: 44,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 38,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 11),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: vehicles.length,
                itemBuilder: (_, index) =>
                    _VehicleCard(vehicle: vehicles[index]),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle});
  final MonitoredVehicle vehicle;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(
        Icons.local_shipping_outlined,
        color: _statusColor(vehicle.status),
      ),
      title: Text(vehicle.vehicleLabel ?? 'Vehículo'),
      subtitle: Text(
        '${vehicle.driverName ?? 'Sin conductor'} · ${_statusLabel(vehicle.status)}${vehicle.recordedAt == null ? '' : '\nÚltima lectura: ${vehicle.recordedAt!.toLocal()}'}',
      ),
      isThreeLine: vehicle.recordedAt != null,
    ),
  );
}

String _statusLabel(LocationStatus status) => switch (status) {
  LocationStatus.fresh => 'Actualizado',
  LocationStatus.stale => 'Desactualizado',
  LocationStatus.offline => 'Fuera de línea',
  LocationStatus.noData => 'Sin datos',
};
Color _statusColor(LocationStatus status) => switch (status) {
  LocationStatus.fresh => Colors.green,
  LocationStatus.stale => Colors.orange,
  LocationStatus.offline => Colors.red,
  LocationStatus.noData => Colors.grey,
};
