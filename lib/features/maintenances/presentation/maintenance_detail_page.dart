import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:rodantex_app/core/auth/user_role.dart';
import 'package:rodantex_app/core/network/api_exception.dart';
import 'package:rodantex_app/features/maintenances/data/maintenance_repository.dart';
import 'package:rodantex_app/features/maintenances/data/models/maintenance.dart';
import 'package:rodantex_app/features/maintenances/presentation/maintenance_page.dart';

/// Consulta, edita o elimina un registro de mantenimiento.
class MaintenanceDetailPage extends StatefulWidget {
  const MaintenanceDetailPage({
    super.key,
    required this.repository,
    required this.maintenanceId,
    required this.role,
  });

  /// Repository que obtiene y modifica el registro.
  final MaintenanceRepository repository;

  /// UUID del mantenimiento.
  final String maintenanceId;
  final UserRole role;

  @override
  State<MaintenanceDetailPage> createState() => _MaintenanceDetailPageState();
}

class _MaintenanceDetailPageState extends State<MaintenanceDetailPage> {
  late Future<Maintenance> _maintenance = widget.repository.getById(
    widget.maintenanceId,
  );

  Future<void> _edit(Maintenance current) async {
    final result = await showDialog<Maintenance>(
      context: context,
      builder: (_) => MaintenanceFormDialog(
        repository: widget.repository,
        initial: current,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _maintenance = Future.value(result);
      });
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar mantenimiento'),
        content: const Text('¿Quieres eliminar este registro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.repository.delete(widget.maintenanceId);
      if (mounted) context.pop();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Detalle del mantenimiento'),
      actions: [
        if (widget.role != UserRole.driver)
          IconButton(
            tooltip: 'Eliminar',
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline),
          ),
      ],
    ),
    body: FutureBuilder<Maintenance>(
      future: _maintenance,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                error is ApiException
                    ? error.message
                    : 'No se pudo cargar el mantenimiento.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final item = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(height: 24),
                    _MaintenanceInfo(
                      label: 'Fecha',
                      value: item.dateOfMaintenance,
                    ),
                    _MaintenanceInfo(
                      label: 'Costo',
                      value: item.cost.toStringAsFixed(2),
                    ),
                    _MaintenanceInfo(label: 'Vehículo', value: item.vehicleId),
                    _MaintenanceInfo(
                      label: 'Proveedor',
                      value: item.supplierId,
                    ),
                    if (item.invoiceUrl?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Factura',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      SelectableText(item.invoiceUrl!),
                    ],
                    const SizedBox(height: 18),
                    if (widget.role != UserRole.driver)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _edit(item),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar mantenimiento'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _MaintenanceInfo extends StatelessWidget {
  const _MaintenanceInfo({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
