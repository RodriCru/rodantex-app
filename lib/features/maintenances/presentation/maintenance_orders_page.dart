import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:rodantex_app/core/network/api_exception.dart';
import 'package:rodantex_app/features/maintenances/data/maintenance_repository.dart';
import 'package:rodantex_app/features/maintenances/data/models/maintenance_order.dart';
import 'package:rodantex_app/features/maintenances/data/models/maintenance_supplier.dart';
import 'package:rodantex_app/features/vehicles/data/models/vehicle.dart';

/// Pantalla principal del flujo de órdenes de mantenimiento.
class MaintenanceOrdersPage extends StatefulWidget {
  const MaintenanceOrdersPage({super.key, required this.repository});
  final MaintenanceRepository repository;

  @override
  State<MaintenanceOrdersPage> createState() => _MaintenanceOrdersPageState();
}

class _MaintenanceOrdersPageState extends State<MaintenanceOrdersPage> {
  late Future<MaintenanceOrderPage> _orders = widget.repository.listOrders();
  final _search = TextEditingController();

  void _reload() {
    setState(() {
      _orders = widget.repository.listOrders(search: _search.text);
    });
  }

  Future<void> _refresh() async {
    final request = widget.repository.listOrders(search: _search.text);
    setState(() {
      _orders = request;
    });
    await request;
  }

  Future<void> _openOrder() async {
    final vehicles = await widget.repository.vehicles();
    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _OpenOrderDialog(repository: widget.repository, vehicles: vehicles),
    );
    if (result == true) _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mantenimientos'),
      actions: [
        IconButton(
          onPressed: _openOrder,
          icon: const Icon(Icons.add),
          tooltip: 'Ingresar vehículo al taller',
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _openOrder,
      icon: const Icon(Icons.build_outlined),
      label: const Text('Ingresar al taller'),
    ),
    body: RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _search,
            onSubmitted: (_) => _reload(),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar órdenes',
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<MaintenanceOrderPage>(
            future: _orders,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done)
                return const Padding(
                  padding: EdgeInsets.all(60),
                  child: Center(child: CircularProgressIndicator()),
                );
              if (snapshot.hasError) return _ErrorText(error: snapshot.error);
              final items = snapshot.data?.items ?? const <MaintenanceOrder>[];
              if (items.isEmpty)
                return const Padding(
                  padding: EdgeInsets.all(60),
                  child: Center(
                    child: Text('No hay órdenes de mantenimiento.'),
                  ),
                );
              return Column(
                children: [
                  for (final order in items)
                    _OrderCard(
                      order: order,
                      repository: widget.repository,
                      onChanged: _reload,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.repository,
    required this.onChanged,
  });
  final MaintenanceOrder order;
  final MaintenanceRepository repository;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final status = switch (order.status) {
      MaintenanceOrderStatus.inProgress => 'En taller',
      MaintenanceOrderStatus.completed => 'Completada',
      MaintenanceOrderStatus.canceled => 'Cancelada',
    };
    final color = order.status == MaintenanceOrderStatus.inProgress
        ? Colors.orange
        : order.status == MaintenanceOrderStatus.completed
        ? Colors.green
        : Colors.grey;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(35),
          child: Icon(Icons.build, color: color),
        ),
        title: Text(
          order.entryDescription,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${order.vehicles.map((v) => v.plate ?? '${v.make} ${v.model}').join(', ')}\n$status',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await showDialog(
            context: context,
            builder: (_) => _OrderDialog(order: order, repository: repository),
          );
          onChanged();
        },
      ),
    );
  }
}

class _OpenOrderDialog extends StatefulWidget {
  const _OpenOrderDialog({required this.repository, required this.vehicles});
  final MaintenanceRepository repository;
  final List<Vehicle> vehicles;
  @override
  State<_OpenOrderDialog> createState() => _OpenOrderDialogState();
}

class _OpenOrderDialogState extends State<_OpenOrderDialog> {
  final _description = TextEditingController();
  String? _vehicle;
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_vehicle == null || _description.text.trim().length < 3) {
      setState(() => _error = 'Selecciona un vehículo y describe el motivo.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repository.createOrder(
        vehicleIds: [_vehicle!],
        entryDescription: _description.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _saving = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Ingresar vehículo al taller'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _vehicle,
            decoration: const InputDecoration(labelText: 'Vehículo'),
            items: [
              for (final v in widget.vehicles)
                DropdownMenuItem(
                  value: v.id,
                  child: Text('${v.displayName} · ${v.plate ?? 'Sin placas'}'),
                ),
            ],
            onChanged: (v) => setState(() => _vehicle = v),
          ),
          TextField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Motivo del ingreso'),
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: const Text('Abrir orden'),
      ),
    ],
  );
}

class _OrderDialog extends StatefulWidget {
  const _OrderDialog({required this.order, required this.repository});
  final MaintenanceOrder order;
  final MaintenanceRepository repository;
  @override
  State<_OrderDialog> createState() => _OrderDialogState();
}

class _OrderDialogState extends State<_OrderDialog> {
  final _description = TextEditingController();
  final _cost = TextEditingController();
  late final Future<List<MaintenanceSupplier>> _suppliers = widget.repository
      .suppliers();
  String? _supplierId;
  DateTime? _serviceDate;
  bool _saving = false;
  String? _error;
  String? _invoiceName;
  List<int>? _invoiceBytes;

  @override
  void dispose() {
    _description.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _serviceDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (value != null) setState(() => _serviceDate = value);
  }

  String _dateValue() {
    final d = _serviceDate!;
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickInvoice() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result.isEmpty || !mounted) return;
    final file = result.first;
    final bytes = await file.readAsBytes();
    if (mounted)
      setState(() {
        _invoiceBytes = bytes;
        _invoiceName = file.name;
      });
  }

  Future<void> _complete() async {
    if (_supplierId == null ||
        _serviceDate == null ||
        _description.text.trim().length < 3 ||
        double.tryParse(_cost.text.replaceAll(',', '.')) == null) {
      setState(
        () => _error = 'Completa proveedor, fecha, trabajo realizado y costo.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.completeOrder(widget.order.id, {
        'supplierId': _supplierId,
        'serviceDate': _dateValue(),
        'serviceDescription': _description.text.trim(),
        'totalCost': double.parse(_cost.text.replaceAll(',', '.')),
      });
      if (_invoiceBytes != null)
        await widget.repository.uploadOrderInvoice(
          id: widget.order.id,
          bytes: _invoiceBytes!,
          filename: _invoiceName!,
        );
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _saving = false;
        });
    }
  }

  Future<void> _cancel() async {
    setState(() => _saving = true);
    try {
      await widget.repository.cancelOrder(widget.order.id);
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _saving = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Row(
      children: [
        const Expanded(child: Text('Orden de mantenimiento')),
        IconButton(
          tooltip: 'Cerrar',
          onPressed: _saving ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    ),
    content: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.order.entryDescription),
          const SizedBox(height: 12),
          if (widget.order.status == MaintenanceOrderStatus.inProgress) ...[
            FutureBuilder<List<MaintenanceSupplier>>(
              future: _suppliers,
              builder: (context, snapshot) => DropdownButtonFormField<String>(
                initialValue: _supplierId,
                decoration: const InputDecoration(labelText: 'Proveedor'),
                items: [
                  for (final s
                      in snapshot.data ?? const <MaintenanceSupplier>[])
                    DropdownMenuItem(value: s.id, child: Text(s.name)),
                ],
                onChanged: (v) => setState(() => _supplierId = v),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha del servicio',
                  suffixIcon: Icon(Icons.calendar_month),
                ),
                child: Text(
                  _serviceDate == null ? 'Selecciona una fecha' : _dateValue(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Trabajo realizado'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cost,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Costo total'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickInvoice,
              icon: const Icon(Icons.attach_file),
              label: Text(_invoiceName ?? 'Adjuntar factura (opcional)'),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ] else
            Text(
              widget.order.status == MaintenanceOrderStatus.completed
                  ? 'Orden completada'
                  : 'Orden cancelada',
            ),
        ],
      ),
    ),
    actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    actions: [
      if (widget.order.status == MaintenanceOrderStatus.inProgress)
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton(
              onPressed: _saving ? null : _cancel,
              child: const Text('Cancelar orden'),
            ),
            FilledButton(
              onPressed: _saving ? null : _complete,
              child: Text(_saving ? 'Guardando…' : 'Registrar trabajo'),
            ),
          ],
        ),
    ],
  );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({this.error});
  final Object? error;
  @override
  Widget build(BuildContext context) => Text(
    error is ApiException
        ? (error as ApiException).message
        : 'No se pudieron cargar las órdenes.',
  );
}
