import 'package:flutter/material.dart';

import 'package:rodantex_app/core/network/api_exception.dart';
import 'package:rodantex_app/features/vehicles/data/models/insurance_supplier.dart';
import 'package:rodantex_app/features/vehicles/data/models/vehicle.dart';
import 'package:rodantex_app/features/vehicles/data/models/vehicle_maintenance.dart';
import 'package:rodantex_app/features/vehicles/data/vehicle_repository.dart';

/// Consulta y presenta el detalle de una unidad.
class VehicleDetailPage extends StatefulWidget {
  const VehicleDetailPage({
    super.key,
    required this.vehicleRepository,
    required this.vehicleId,
  });

  final VehicleRepository vehicleRepository;
  final String vehicleId;

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  late Future<Vehicle> _vehicle = widget.vehicleRepository.getById(
    widget.vehicleId,
  );
  late Future<VehicleMaintenance?> _maintenance = _loadMaintenance();

  Future<VehicleMaintenance?> _loadMaintenance() async {
    try {
      return await widget.vehicleRepository.getMaintenance(widget.vehicleId);
    } on ApiException catch (error) {
      // El endpoint devuelve 404 cuando el vehículo aún no tiene este registro.
      if (error.isNotFound) return null;
      rethrow;
    }
  }

  void _retry() => setState(() {
    _vehicle = widget.vehicleRepository.getById(widget.vehicleId);
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalle del vehículo')),
    body: FutureBuilder<Vehicle>(
      future: _vehicle,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          final message = error is ApiException
              ? error.message
              : 'No se pudo cargar el vehículo.';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _retry,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        final vehicle = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (vehicle.photoUrl?.isNotEmpty ?? false)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  vehicle.photoUrl!,
                  height: 210,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.displayName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Chip(label: Text(vehicle.status.label)),
                    const Divider(height: 24),
                    _DetailRow(label: 'Placas', value: vehicle.plate),
                    _DetailRow(
                      label: 'Número económico',
                      value: vehicle.numberEco,
                    ),
                    _DetailRow(label: 'Tipo', value: vehicle.carType),
                    _DetailRow(label: 'Combustible', value: vehicle.gasoline),
                    _DetailRow(
                      label: 'Capacidad de combustible',
                      value: vehicle.fuelCapacity?.toString(),
                    ),
                    _DetailRow(
                      label: 'Llantas',
                      value: vehicle.numberOfTires?.toString(),
                    ),
                    _DetailRow(
                      label: 'Llanta de refacción',
                      value: vehicle.hasSpareTire == null
                          ? null
                          : vehicle.hasSpareTire!
                          ? 'Sí'
                          : 'No',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _maintenanceSection(),
          ],
        );
      },
    ),
  );

  Widget _maintenanceSection() => FutureBuilder<VehicleMaintenance?>(
    future: _maintenance,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }
      if (snapshot.hasError) {
        final error = snapshot.error;
        final message = error is ApiException
            ? error.message
            : 'No se pudieron cargar los datos de mantenimiento.';
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mantenimiento',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(message),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _maintenance = _loadMaintenance();
                    }),
                    child: const Text('Reintentar'),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final maintenance = snapshot.data;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mantenimiento y documentos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: maintenance == null ? 'Registrar' : 'Editar',
                    onPressed: () => _editMaintenance(maintenance),
                    icon: Icon(
                      maintenance == null ? Icons.add : Icons.edit_outlined,
                    ),
                  ),
                ],
              ),
              if (maintenance == null) ...[
                const Text('Aún no hay datos de mantenimiento registrados.'),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _editMaintenance(null),
                  icon: const Icon(Icons.add),
                  label: const Text('Registrar datos'),
                ),
              ] else ...[
                _DetailRow(
                  label: 'Próxima verificación',
                  value: maintenance.nextVerification,
                ),
                _DetailRow(
                  label: 'Vencimiento de placas',
                  value: maintenance.licensePlateExpiration,
                ),
                _DetailRow(
                  label: 'Vencimiento de seguro',
                  value: maintenance.insuranceExpiration,
                ),
                _DetailRow(label: 'Póliza', value: maintenance.insurancePolicy),
                _DetailRow(
                  label: 'Odómetro',
                  value: maintenance.odometer?.toString(),
                ),
                _DetailRow(
                  label: 'Intervalo de mantenimiento',
                  value: maintenance.maintenanceIntervalKm == null
                      ? null
                      : '${maintenance.maintenanceIntervalKm} km',
                ),
              ],
            ],
          ),
        ),
      );
    },
  );

  Future<void> _editMaintenance(VehicleMaintenance? current) async {
    final result = await showDialog<VehicleMaintenance>(
      context: context,
      builder: (_) => _MaintenanceFormDialog(
        repository: widget.vehicleRepository,
        vehicleId: widget.vehicleId,
        initial: current,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _maintenance = Future.value(result);
      });
    }
  }
}

class _MaintenanceFormDialog extends StatefulWidget {
  const _MaintenanceFormDialog({
    required this.repository,
    required this.vehicleId,
    required this.initial,
  });

  final VehicleRepository repository;
  final String vehicleId;
  final VehicleMaintenance? initial;

  @override
  State<_MaintenanceFormDialog> createState() => _MaintenanceFormDialogState();
}

class _MaintenanceFormDialogState extends State<_MaintenanceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nextVerification = _controller(widget.initial?.nextVerification);
  late final _insuranceExpiration = _controller(
    widget.initial?.insuranceExpiration,
  );
  late final _insurancePolicy = _controller(widget.initial?.insurancePolicy);
  late final _maintenanceInterval = _controller(
    widget.initial?.maintenanceIntervalKm?.toString(),
  );
  late final _odometer = _controller(widget.initial?.odometer?.toString());
  late final _licensePlateExpiration = _controller(
    widget.initial?.licensePlateExpiration,
  );
  late final Future<List<InsuranceSupplier>> _suppliers = widget.repository
      .insuranceSuppliers();
  String? _insuranceSupplierId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _insuranceSupplierId = widget.initial?.insuranceSupplierId;
  }

  TextEditingController _controller(String? value) =>
      TextEditingController(text: value ?? '');

  @override
  void dispose() {
    _nextVerification.dispose();
    _insuranceExpiration.dispose();
    _insurancePolicy.dispose();
    _maintenanceInterval.dispose();
    _odometer.dispose();
    _licensePlateExpiration.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final today = DateTime.now();
    final current = DateTime.tryParse(controller.text);
    final selected = await showDatePicker(
      context: context,
      initialDate: current ?? today,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) return;
    controller.text =
        '${selected.year.toString().padLeft(4, '0')}-'
        '${selected.month.toString().padLeft(2, '0')}-'
        '${selected.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final data = <String, dynamic>{
      'nextVerification': _value(_nextVerification),
      'insuranceExpiration': _value(_insuranceExpiration),
      'insuranceSupplierId': _insuranceSupplierId,
      'insurancePolicy': _value(_insurancePolicy),
      'maintenanceIntervalKm': int.tryParse(_maintenanceInterval.text.trim()),
      'odometer': double.tryParse(_odometer.text.trim()),
      'licensePlateExpiration': _value(_licensePlateExpiration),
    }..removeWhere((_, value) => value == null);

    try {
      final saved = widget.initial == null
          ? await widget.repository.createMaintenance(widget.vehicleId, data)
          : await widget.repository.updateMaintenance(widget.vehicleId, data);
      if (mounted) Navigator.of(context).pop(saved);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Object {
      if (mounted) setState(() => _error = 'No se pudieron guardar los datos.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _value(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text(
      widget.initial == null
          ? 'Registrar mantenimiento'
          : 'Editar mantenimiento',
    ),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dateField('Próxima verificación', _nextVerification),
              _dateField('Vencimiento de seguro', _insuranceExpiration),
              _insuranceSupplierField(),
              _textField('Póliza de seguro', _insurancePolicy),
              _numberField(
                'Intervalo de mantenimiento (km)',
                _maintenanceInterval,
                integer: true,
              ),
              _numberField('Odómetro (km)', _odometer),
              _dateField('Vencimiento de placas', _licensePlateExpiration),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Guardar'),
      ),
    ],
  );

  Widget _dateField(String label, TextEditingController controller) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _pickDate(controller),
      style: const TextStyle(fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        suffixIcon: IconButton(
          tooltip: 'Elegir fecha',
          onPressed: () => _pickDate(controller),
          icon: const Icon(Icons.calendar_month_outlined),
        ),
      ),
    ),
  );

  Widget _insuranceSupplierField() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: FutureBuilder<List<InsuranceSupplier>>(
      future: _suppliers,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LinearProgressIndicator();
        }
        final suppliers = [...?snapshot.data];
        final currentId = _insuranceSupplierId;
        if (currentId != null &&
            !suppliers.any((supplier) => supplier.id == currentId)) {
          suppliers.add(
            InsuranceSupplier(id: currentId, name: 'Aseguradora actual'),
          );
        }
        return DropdownButtonFormField<String>(
          initialValue: currentId ?? '',
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Aseguradora (opcional)',
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            helperText: snapshot.hasError
                ? 'No se pudo cargar la lista de aseguradoras.'
                : null,
          ),
          items: [
            const DropdownMenuItem<String>(
              value: '',
              child: Text('Sin aseguradora'),
            ),
            for (final supplier in suppliers)
              DropdownMenuItem<String>(
                value: supplier.id,
                child: Text(supplier.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (value) => setState(() {
            _insuranceSupplierId = value == null || value.isEmpty
                ? null
                : value;
          }),
        );
      },
    ),
  );

  Widget _textField(String label, TextEditingController controller) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      style: const TextStyle(fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );

  Widget _numberField(
    String label,
    TextEditingController controller, {
    bool integer = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontWeight: FontWeight.w700),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return null;
        return (integer ? int.tryParse(text) : double.tryParse(text)) == null
            ? 'Ingresa un número válido'
            : null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value?.isNotEmpty == true ? value! : '—',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
