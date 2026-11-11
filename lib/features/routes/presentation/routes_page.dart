import 'package:flutter/material.dart';
import 'package:rodantex_app/core/auth/user_role.dart';
import 'package:rodantex_app/core/network/api_exception.dart';
import 'package:rodantex_app/features/routes/data/models/route.dart';
import 'package:rodantex_app/features/routes/data/models/trip.dart';
import 'package:rodantex_app/features/routes/data/models/trip_expense.dart';
import 'package:rodantex_app/features/routes/data/routes_repository.dart';
import 'package:rodantex_app/features/routes/data/trip_location_queue.dart';
import 'package:rodantex_app/features/routes/data/trip_tracking_service.dart';
import 'package:go_router/go_router.dart';
import 'package:rodantex_app/app/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Consulta rutas y viajes asignados; no permite crear rutas ni viajes.
class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key, required this.repository, required this.role});
  final RoutesRepository repository;
  final UserRole role;
  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  late Future<List<FleetRoute>> _routes = widget.repository.listRoutes();
  late Future<List<FleetTrip>> _trips = _loadTrips();
  TripTrackingService? _tracking;

  Future<List<FleetTrip>> _loadTrips() async {
    final trips = await widget.repository.listTrips();
    if (widget.role != UserRole.driver) return trips;
    final preferences = await SharedPreferences.getInstance();
    final tracking = _tracking ??= TripTrackingService(
      repository: widget.repository,
      queue: TripLocationQueue(preferences),
    );
    final activeTrips = trips.where(
      (trip) => trip.status == TripStatus.inProgress,
    );
    final active = activeTrips.isEmpty ? null : activeTrips.first;
    if (active == null) {
      await tracking.stop();
    } else {
      await tracking.start(active);
    }
    return trips;
  }

  @override
  void dispose() {
    _tracking?.dispose();
    super.dispose();
  }

  void _reload() => setState(() {
    _routes = widget.repository.listRoutes();
    _trips = _loadTrips();
  });
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Rutas y viajes'),
        actions: [
          if (widget.role == UserRole.superAdmin ||
              widget.role == UserRole.owner ||
              widget.role == UserRole.manager ||
              widget.role == UserRole.accountant)
            IconButton(
              onPressed: () => context.push(AppRoutes.monitoring),
              tooltip: 'Monitoreo',
              icon: const Icon(Icons.location_on_outlined),
            ),
        ],
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
            _TripsList(
              future: _trips,
              repository: widget.repository,
              role: widget.role,
              onChanged: _reload,
            ),
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
  const _TripsList({
    required this.future,
    required this.repository,
    required this.role,
    required this.onChanged,
  });
  final Future<List<FleetTrip>> future;
  final RoutesRepository repository;
  final UserRole role;
  final VoidCallback onChanged;
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
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => _TripDialog(
                      trip: trip,
                      repository: repository,
                      role: role,
                    ),
                  );
                  onChanged();
                },
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
  const _TripDialog({
    required this.trip,
    required this.repository,
    required this.role,
  });
  final FleetTrip trip;
  final RoutesRepository repository;
  final UserRole role;
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
          const SizedBox(height: 16),
          if (widget.role != UserRole.mechanic)
            _TripExpenses(
              repository: widget.repository,
              tripId: widget.trip.id,
              role: widget.role,
            ),
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

class _TripExpenses extends StatefulWidget {
  const _TripExpenses({
    required this.repository,
    required this.tripId,
    required this.role,
  });
  final RoutesRepository repository;
  final String tripId;
  final UserRole role;

  @override
  State<_TripExpenses> createState() => _TripExpensesState();
}

class _TripExpensesState extends State<_TripExpenses> {
  late Future<List<TripExpense>> _future = widget.repository.listTripExpenses(
    widget.tripId,
  );

  void _reload() => setState(
    () => _future = widget.repository.listTripExpenses(widget.tripId),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Gastos', style: TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            tooltip: 'Agregar gasto',
            onPressed: widget.role == UserRole.mechanic
                ? null
                : () async {
                    final saved = await showDialog<bool>(
                      context: context,
                      builder: (_) => _ExpenseForm(
                        repository: widget.repository,
                        tripId: widget.tripId,
                      ),
                    );
                    if (saved == true && mounted) _reload();
                  },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      FutureBuilder<List<TripExpense>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError)
            return Text('No se pudieron cargar los gastos.');
          final expenses = snapshot.data ?? const <TripExpense>[];
          if (expenses.isEmpty) return const Text('Sin gastos registrados.');
          return Column(
            children: [
              for (final expense in expenses)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    '${expense.type.label} · \$${expense.amount.toStringAsFixed(2)}',
                  ),
                  subtitle: Text(expense.description ?? 'Sin descripción'),
                  trailing: _canManageExpenses(widget.role)
                      ? PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              final saved = await showDialog<bool>(
                                context: context,
                                builder: (_) => _ExpenseForm(
                                  repository: widget.repository,
                                  tripId: widget.tripId,
                                  expense: expense,
                                ),
                              );
                              if (saved == true && mounted) _reload();
                            } else if (value == 'delete') {
                              await widget.repository.deleteTripExpense(
                                expense.id,
                              );
                              if (mounted) _reload();
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Editar')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Eliminar'),
                            ),
                          ],
                        )
                      : null,
                ),
            ],
          );
        },
      ),
    ],
  );
}

bool _canManageExpenses(UserRole role) => switch (role) {
  UserRole.superAdmin ||
  UserRole.owner ||
  UserRole.manager ||
  UserRole.accountant => true,
  UserRole.driver || UserRole.mechanic || UserRole.unknown => false,
};

class _ExpenseForm extends StatefulWidget {
  const _ExpenseForm({
    required this.repository,
    required this.tripId,
    this.expense,
  });
  final RoutesRepository repository;
  final String tripId;
  final TripExpense? expense;

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  late TripExpenseType _type = widget.expense?.type ?? TripExpenseType.fuel;
  late final _amount = TextEditingController(
    text: widget.expense?.amount.toString() ?? '',
  );
  late final _liters = TextEditingController(
    text: widget.expense?.liters?.toString() ?? '',
  );
  late final _odometer = TextEditingController(
    text: widget.expense?.odometer?.toString() ?? '',
  );
  late final _description = TextEditingController(
    text: widget.expense?.description ?? '',
  );
  DateTime? _date;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _date = widget.expense?.expenseDate;
  }

  @override
  void dispose() {
    _amount.dispose();
    _liters.dispose();
    _odometer.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.replaceAll(',', '.'));
    final liters = double.tryParse(_liters.text.replaceAll(',', '.'));
    final odometer = double.tryParse(_odometer.text.replaceAll(',', '.'));
    if (amount == null ||
        amount < 0 ||
        (_type == TripExpenseType.fuel && (liters == null || liters <= 0))) {
      setState(
        () => _error = 'Captura un importe válido y litros mayores a cero para combustible.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final data = <String, dynamic>{
      'type': _type.apiValue,
      'amount': amount,
      'description': _description.text.trim(),
    };
    if (liters != null) data['liters'] = liters;
    if (odometer != null) data['odometer'] = odometer;
    if (_date != null) data['expenseDate'] = _date!.toUtc().toIso8601String();
    try {
      if (widget.expense == null) {
        await widget.repository.createTripExpense(widget.tripId, data);
      } else {
        await widget.repository.updateTripExpense(widget.expense!.id, data);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _saving = false;
          _error = e.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.expense == null ? 'Agregar gasto' : 'Editar gasto'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<TripExpenseType>(
            value: _type,
            decoration: const InputDecoration(
              labelText: 'Tipo',
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
            items: [
              for (final type in TripExpenseType.values)
                DropdownMenuItem(value: type, child: Text(type.label)),
            ],
            onChanged: _saving
                ? null
                : (value) => setState(() => _type = value!),
          ),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Importe',
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (_type == TripExpenseType.fuel)
            TextField(
              controller: _liters,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Litros',
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          TextField(
            controller: _odometer,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Odómetro',
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TextField(
            controller: _description,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Fecha del gasto',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _date == null
                  ? 'Seleccionar fecha y hora'
                  : _date!.toLocal().toString(),
            ),
            trailing: const Icon(Icons.calendar_month),
            onTap: _saving
                ? null
                : () async {
                    final day = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDate: _date ?? DateTime.now(),
                    );
                    if (day == null || !context.mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(
                        _date ?? DateTime.now(),
                      ),
                    );
                    if (time != null)
                      setState(
                        () => _date = DateTime(
                          day.year,
                          day.month,
                          day.day,
                          time.hour,
                          time.minute,
                        ),
                      );
                  },
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
        child: const Text('Guardar'),
      ),
    ],
  );
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
