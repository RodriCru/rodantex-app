import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:rodantex_app/app/routes.dart';
import 'package:rodantex_app/core/theme/rodantex_colors.dart';
import 'package:rodantex_app/features/vehicles/data/models/vehicle.dart';
import 'package:rodantex_app/features/vehicles/data/vehicle_repository.dart';
import 'package:rodantex_app/features/vehicles/presentation/vehicles_controller.dart';

/// Lista vehículos activos del tenant con búsqueda y paginación.
class VehiclesPage extends StatefulWidget {
  const VehiclesPage({super.key, required this.vehicleRepository});

  final VehicleRepository vehicleRepository;

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  late final VehiclesController _controller = VehiclesController(
    widget.vehicleRepository,
  )..load();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Vehículos')),
    body: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => RefreshIndicator(
        onRefresh: () => _controller.load(refresh: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => _controller.load(search: value),
              decoration: InputDecoration(
                hintText: 'Buscar por placa, marca o modelo',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Buscar',
                  onPressed: () =>
                      _controller.load(search: _searchController.text),
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_controller.error != null && _controller.vehicles.isEmpty)
              _ErrorPanel(
                message: _controller.error!,
                onRetry: () => _controller.load(refresh: true),
              )
            else if (_controller.isLoading && _controller.vehicles.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_controller.vehicles.isEmpty)
              const _EmptyPanel()
            else ...[
              Text(
                '${_controller.total} ${_controller.total == 1 ? 'vehículo' : 'vehículos'}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              for (final vehicle in _controller.vehicles)
                _VehicleTile(
                  vehicle: vehicle,
                  onTap: () =>
                      context.push(AppRoutes.vehicleDetail(vehicle.id)),
                ),
              if (_controller.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(_controller.error!, textAlign: TextAlign.center),
                ),
              if (_controller.hasNextPage)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    onPressed: _controller.isLoadingMore
                        ? null
                        : _controller.loadMore,
                    icon: _controller.isLoadingMore
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more),
                    label: Text(
                      _controller.isLoadingMore ? 'Cargando…' : 'Ver más',
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({required this.vehicle, required this.onTap});

  final Vehicle vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: RodantexColors.secondaryLight,
          foregroundColor: RodantexColors.primary,
          backgroundImage: vehicle.photoUrl == null || vehicle.photoUrl!.isEmpty
              ? null
              : NetworkImage(vehicle.photoUrl!),
          child: vehicle.photoUrl == null || vehicle.photoUrl!.isEmpty
              ? const Icon(Icons.local_shipping_outlined)
              : null,
        ),
        title: Text(
          vehicle.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            [
                  if (vehicle.plate?.isNotEmpty ?? false) vehicle.plate!,
                  if (vehicle.numberEco?.isNotEmpty ?? false)
                    'Eco. ${vehicle.numberEco}',
                ].join(' · ').isEmpty
                ? 'Sin placa registrada'
                : [
                    if (vehicle.plate?.isNotEmpty ?? false) vehicle.plate!,
                    if (vehicle.numberEco?.isNotEmpty ?? false)
                      'Eco. ${vehicle.numberEco}',
                  ].join(' · '),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _StatusPill(status: vehicle.status),
            const SizedBox(height: 5),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final VehicleStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isGood = status == VehicleStatus.inService;
    final isMaintenance = status == VehicleStatus.inMaintenance;
    final background = isGood
        ? const Color(0xFFE8F2C6)
        : isMaintenance
        ? const Color(0xFFFBEED4)
        : const Color(0xFFE7EBEE);
    final foreground = isGood
        ? const Color(0xFF3D5210)
        : isMaintenance
        ? const Color(0xFF7A4E0F)
        : colors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 88),
    child: Column(
      children: [
        Icon(Icons.directions_car_outlined, size: 44),
        SizedBox(height: 12),
        Text('No hay vehículos para mostrar'),
        SizedBox(height: 4),
        Text('Prueba con otra búsqueda.'),
      ],
    ),
  );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 72),
    child: Column(
      children: [
        const Icon(Icons.cloud_off_outlined, size: 44),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    ),
  );
}
