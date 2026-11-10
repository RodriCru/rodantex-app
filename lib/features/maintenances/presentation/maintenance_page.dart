import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:rodantex_app/app/routes.dart';
import 'package:rodantex_app/core/network/api_exception.dart';
import 'package:rodantex_app/features/maintenances/data/maintenance_repository.dart';
import 'package:rodantex_app/features/maintenances/data/models/maintenance.dart';
import 'package:rodantex_app/features/maintenances/data/models/maintenance_supplier.dart';
import 'package:rodantex_app/features/maintenances/presentation/maintenance_controller.dart';
import 'package:rodantex_app/features/vehicles/data/models/vehicle.dart';

/// Lista, busca y registra servicios realizados a los vehículos.
class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key, required this.repository});

  final MaintenanceRepository repository;

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  late final MaintenanceController _controller = MaintenanceController(
    widget.repository,
  )..load();
  final _search = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final result = await showDialog<Maintenance>(
      context: context,
      builder: (_) => MaintenanceFormDialog(repository: widget.repository),
    );
    if (result != null) await _controller.load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mantenimientos'),
      actions: [
        IconButton(
          tooltip: 'Registrar mantenimiento',
          onPressed: _create,
          icon: const Icon(Icons.add),
        ),
      ],
    ),
    body: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => RefreshIndicator(
        onRefresh: () => _controller.load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => _controller.load(search: value),
              decoration: InputDecoration(
                hintText: 'Buscar mantenimientos',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Buscar',
                  onPressed: () => _controller.load(search: _search.text),
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_controller.isLoading && _controller.items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_controller.error != null && _controller.items.isEmpty)
              _ErrorState(
                message: _controller.error!,
                onRetry: () => _controller.load(),
              )
            else if (_controller.items.isEmpty)
              _EmptyState(onCreate: _create)
            else ...[
              Text('${_controller.total} registros'),
              const SizedBox(height: 8),
              for (final item in _controller.items)
                _MaintenanceListTile(
                  item: item,
                  onTap: () =>
                      context.push(AppRoutes.maintenanceDetail(item.id)),
                ),
              if (_controller.error != null)
                Text(_controller.error!, textAlign: TextAlign.center),
              if (_controller.hasNextPage)
                OutlinedButton.icon(
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
            ],
          ],
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _create,
      icon: const Icon(Icons.add),
      label: const Text('Registrar'),
    ),
  );
}

class _MaintenanceListTile extends StatelessWidget {
  const _MaintenanceListTile({required this.item, required this.onTap});

  final Maintenance item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 8),
    child: ListTile(
      onTap: onTap,
      leading: const CircleAvatar(child: Icon(Icons.build_circle_outlined)),
      title: Text(
        item.description.isEmpty
            ? 'Servicio de mantenimiento'
            : item.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${item.dateOfMaintenance} · Vehículo ${_shortId(item.vehicleId)}',
      ),
      trailing: Text(
        item.cost.toStringAsFixed(2),
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
  );

  String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 72),
    child: Column(
      children: [
        const Icon(Icons.handyman_outlined, size: 48),
        const SizedBox(height: 12),
        const Text('Aún no hay mantenimientos registrados.'),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add),
          label: const Text('Registrar mantenimiento'),
        ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 72),
    child: Column(
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    ),
  );
}

/// Formulario para crear o editar un mantenimiento registrado.
class MaintenanceFormDialog extends StatefulWidget {
  const MaintenanceFormDialog({
    super.key,
    required this.repository,
    this.initial,
  });

  /// Repository que crea o actualiza el registro.
  final MaintenanceRepository repository;

  /// Registro existente; `null` inicia un alta.
  final Maintenance? initial;

  @override
  State<MaintenanceFormDialog> createState() => _MaintenanceFormDialogState();
}

class _MaintenanceFormDialogState extends State<MaintenanceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _cost = TextEditingController();
  late final Future<List<Vehicle>> _vehicles = widget.repository.vehicles();
  late final Future<List<MaintenanceSupplier>> _suppliers = widget.repository
      .suppliers();
  String? _vehicleId;
  String? _supplierId;
  DateTime? _date;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _description.text = initial?.description ?? '';
    _cost.text = initial?.cost.toString() ?? '';
    _vehicleId = initial?.vehicleId;
    _supplierId = initial?.supplierId;
    _date = DateTime.tryParse(initial?.dateOfMaintenance ?? '');
  }

  @override
  void dispose() {
    _description.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  String? get _dateValue {
    final date = _date;
    if (date == null) return null;
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final data = <String, dynamic>{
      'supplierId': _supplierId,
      'dateOfMaintenance': _dateValue,
      'description': _description.text.trim(),
      'cost': double.tryParse(_cost.text.trim()),
      if (widget.initial == null) 'vehicleId': _vehicleId,
    }..removeWhere((_, value) => value == null);
    try {
      final saved = widget.initial == null
          ? await widget.repository.create(data)
          : await widget.repository.update(widget.initial!.id, data);
      if (mounted) Navigator.of(context).pop(saved);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Object {
      if (mounted) {
        setState(() => _error = 'No se pudo guardar el mantenimiento.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
              if (widget.initial == null) _vehicleField(),
              _supplierField(),
              FormField<DateTime>(
                initialValue: _date,
                validator: (_) => _date == null ? 'Selecciona la fecha' : null,
                builder: (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Fecha del mantenimiento',
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                        suffixIcon: const Icon(Icons.calendar_month_outlined),
                        errorText: field.errorText,
                      ),
                      child: Text(
                        _dateValue ?? 'Selecciona una fecha',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
              TextFormField(
                controller: _description,
                minLines: 2,
                maxLines: 4,
                style: const TextStyle(fontWeight: FontWeight.w700),
                decoration: _decoration(context, 'Descripción'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Escribe qué trabajo se realizó'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cost,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(fontWeight: FontWeight.w700),
                decoration: _decoration(context, 'Costo'),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  return amount == null || amount < 0
                      ? 'Ingresa un costo válido'
                      : null;
                },
              ),
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

  InputDecoration _decoration(BuildContext context, String label) =>
      InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      );

  Widget _vehicleField() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: FutureBuilder<List<Vehicle>>(
      future: _vehicles,
      builder: (context, snapshot) {
        final vehicles = snapshot.data ?? const <Vehicle>[];
        return DropdownButtonFormField<String>(
          initialValue: _vehicleId,
          isExpanded: true,
          decoration: _decoration(context, 'Vehículo'),
          items: [
            for (final vehicle in vehicles)
              DropdownMenuItem(
                value: vehicle.id,
                child: Text(
                  '${vehicle.displayName} · ${vehicle.plate ?? 'Sin placas'}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: snapshot.connectionState != ConnectionState.done
              ? null
              : (value) => setState(() => _vehicleId = value),
          validator: (value) => value == null ? 'Selecciona un vehículo' : null,
          hint: Text(
            snapshot.hasError
                ? 'No se pudieron cargar vehículos'
                : 'Selecciona',
          ),
        );
      },
    ),
  );

  Widget _supplierField() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: FutureBuilder<List<MaintenanceSupplier>>(
      future: _suppliers,
      builder: (context, snapshot) {
        final suppliers = [...?snapshot.data];
        final currentSupplierId = _supplierId;
        if (currentSupplierId != null &&
            !suppliers.any((supplier) => supplier.id == currentSupplierId)) {
          suppliers.add(
            MaintenanceSupplier(
              id: currentSupplierId,
              name: 'Proveedor actual',
            ),
          );
        }
        return DropdownButtonFormField<String>(
          initialValue: _supplierId ?? '',
          isExpanded: true,
          decoration: _decoration(context, 'Proveedor'),
          items: [
            const DropdownMenuItem<String>(
              value: '',
              child: Text('Sin proveedor'),
            ),
            for (final supplier in suppliers)
              DropdownMenuItem(
                value: supplier.id,
                child: Text(supplier.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: snapshot.connectionState != ConnectionState.done
              ? null
              : (value) => setState(() {
                  _supplierId = value == null || value.isEmpty ? null : value;
                }),
          hint: Text(
            snapshot.hasError
                ? 'No se pudieron cargar proveedores'
                : 'Selecciona',
          ),
        );
      },
    ),
  );
}
