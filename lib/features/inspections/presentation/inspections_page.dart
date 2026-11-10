import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:rodantex_app/app/routes.dart';
import 'package:rodantex_app/core/network/api_exception.dart';
import 'package:rodantex_app/features/inspections/data/inspection_repository.dart';
import 'package:rodantex_app/features/inspections/data/models/inspection.dart';
import 'package:rodantex_app/features/inspections/data/models/inspection_rules.dart';
import 'package:rodantex_app/features/inspections/data/models/inspection_tire.dart';
import 'package:rodantex_app/features/vehicles/data/models/vehicle.dart';

/// Historial y registro de inspecciones filtrados por vehículo.
class InspectionsPage extends StatefulWidget {
  const InspectionsPage({super.key, required this.repository});

  final InspectionRepository repository;

  @override
  State<InspectionsPage> createState() => _InspectionsPageState();
}

class _InspectionsPageState extends State<InspectionsPage> {
  late final Future<List<Vehicle>> _vehicles = widget.repository.vehicles();
  String? _vehicleId;
  Future<InspectionPage>? _history;
  List<TireInspection> _items = const [];
  int _page = 1;
  int _total = 0;
  bool _hasNext = false;
  bool _loadingMore = false;
  String? _error;

  void _selectVehicle(String? vehicleId) {
    if (vehicleId == null) return;
    setState(() {
      _vehicleId = vehicleId;
      _items = const [];
      _page = 1;
      _error = null;
      _history = widget.repository
          .byVehicle(vehicleId)
          .then((result) {
            if (mounted && _vehicleId == vehicleId) {
              setState(() {
                _items = result.items;
                _total = result.total;
                _page = result.page;
                _hasNext = result.hasNextPage;
              });
            }
            return result;
          })
          .catchError((Object error) {
            if (mounted && _vehicleId == vehicleId) {
              setState(
                () => _error = error is ApiException
                    ? error.message
                    : 'No se pudo cargar el historial.',
              );
            }
            throw error;
          });
    });
  }

  Future<void> _loadMore() async {
    final id = _vehicleId;
    if (id == null || _loadingMore || !_hasNext) return;
    setState(() {
      _loadingMore = true;
      _error = null;
    });
    try {
      final result = await widget.repository.byVehicle(id, page: _page + 1);
      if (!mounted || _vehicleId != id) return;
      setState(() {
        _items = [..._items, ...result.items];
        _page = result.page;
        _total = result.total;
        _hasNext = result.hasNextPage;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _create() async {
    final vehicleId = _vehicleId;
    if (vehicleId == null) return;
    final result = await showDialog<TireInspection>(
      context: context,
      builder: (_) => InspectionFormDialog(
        repository: widget.repository,
        vehicleId: vehicleId,
      ),
    );
    if (result != null && mounted) _selectVehicle(vehicleId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Inspecciones'),
      actions: [
        IconButton(
          tooltip: 'Reglas de inspección',
          onPressed: () => context.push(AppRoutes.inspectionRules),
          icon: const Icon(Icons.tune),
        ),
      ],
    ),
    body: FutureBuilder<List<Vehicle>>(
      future: _vehicles,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error is ApiException
                  ? (snapshot.error! as ApiException).message
                  : 'No se pudieron cargar los vehículos.',
            ),
          );
        }
        final vehicles = snapshot.data ?? const <Vehicle>[];
        if (vehicles.isEmpty) {
          return const Center(child: Text('Primero registra un vehículo.'));
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<String>(
                initialValue: _vehicleId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Vehículo',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                hint: const Text('Selecciona un vehículo'),
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
                onChanged: _selectVehicle,
              ),
            ),
            Expanded(child: _historyList()),
          ],
        );
      },
    ),
    floatingActionButton: _vehicleId == null
        ? null
        : FloatingActionButton.extended(
            onPressed: _create,
            icon: const Icon(Icons.add),
            label: const Text('Nueva inspección'),
          ),
  );

  Widget _historyList() {
    if (_vehicleId == null) {
      return const Center(
        child: Text('Selecciona un vehículo para ver su historial.'),
      );
    }
    if (_history == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return FutureBuilder<InspectionPage>(
      future: _history,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done &&
            _items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_error != null && _items.isEmpty) {
          return Center(child: Text(_error!, textAlign: TextAlign.center));
        }
        if (_items.isEmpty) {
          return const Center(
            child: Text('Este vehículo aún no tiene inspecciones.'),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 92),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('$_total inspecciones'),
            ),
            for (final inspection in _items)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () async {
                    final deleted = await context.push<bool>(
                      AppRoutes.inspectionDetail(inspection.id),
                    );
                    if (deleted == true && mounted && _vehicleId != null) {
                      _selectVehicle(_vehicleId);
                    }
                  },
                  leading: const CircleAvatar(
                    child: Icon(Icons.fact_check_outlined),
                  ),
                  title: Text(
                    inspection.description.isEmpty
                        ? 'Inspección de llantas'
                        : inspection.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(inspection.dateOfInspection),
                  trailing: _InspectionStatusChip(status: inspection.status),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            if (_hasNext)
              OutlinedButton.icon(
                onPressed: _loadingMore ? null : _loadMore,
                icon: _loadingMore
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more),
                label: Text(_loadingMore ? 'Cargando…' : 'Ver más'),
              ),
          ],
        );
      },
    );
  }
}

class _InspectionStatusChip extends StatelessWidget {
  const _InspectionStatusChip({required this.status});
  final InspectionStatus status;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(status.label, style: const TextStyle(fontSize: 11)),
    visualDensity: VisualDensity.compact,
  );
}

/// Formulario para registrar o editar una inspección y sus mediciones.
class InspectionFormDialog extends StatefulWidget {
  const InspectionFormDialog({
    super.key,
    required this.repository,
    required this.vehicleId,
    this.initial,
  });

  final InspectionRepository repository;
  final String vehicleId;
  final TireInspection? initial;

  @override
  State<InspectionFormDialog> createState() => _InspectionFormDialogState();
}

class _InspectionFormDialogState extends State<InspectionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  late final Future<_InspectionSetup> _setup = _loadSetup();
  DateTime? _date;
  List<_TireDraft> _drafts = [];
  bool _draftsInitialized = false;
  bool _saving = false;
  String? _error;

  Future<_InspectionSetup> _loadSetup() async {
    final results = await Future.wait([
      widget.repository.vehicles(),
      widget.repository.tiresForVehicle(widget.vehicleId),
    ]);
    final vehicles = results[0] as List<Vehicle>;
    final tires = results[1] as List<VehicleInspectionTire>;
    Vehicle? vehicle;
    for (final item in vehicles) {
      if (item.id == widget.vehicleId) {
        vehicle = item;
        break;
      }
    }
    if (vehicle == null || (vehicle.carType ?? '').isEmpty) {
      throw ApiException(
        'No se pudo determinar el tipo de vehículo para aplicar las reglas.',
      );
    }
    final rules = await widget.repository.getRules(carType: vehicle.carType);
    return _InspectionSetup(tires: tires, rules: rules);
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _description.text = initial?.description ?? '';
    _date = DateTime.tryParse(initial?.dateOfInspection ?? '');
    if (initial != null) {
      _drafts = initial.tires.map(_TireDraft.fromInspection).toList();
      _draftsInitialized = true;
    }
  }

  @override
  void dispose() {
    _description.dispose();
    for (final draft in _drafts) {
      draft.dispose();
    }
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
    final selected = _drafts.where((draft) => draft.selected).toList();
    if (selected.isEmpty) {
      setState(() => _error = 'Selecciona al menos una llanta.');
      return;
    }
    if (selected.any(
      (draft) =>
          draft.average == null ||
          _setupRules == null ||
          _setupRules!.statusForAverage(draft.average!) == null,
    )) {
      setState(
        () => _error = 'Completa las tres mediciones y verifica que existan reglas para el vehículo.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final data = <String, dynamic>{
      'dateOfInspection': _dateValue,
      'description': _description.text.trim(),
      'tires': [
        for (final draft in selected)
          {
            if (widget.initial == null)
              'tireId': draft.tireId
            else
              'id': draft.inspectionTireId,
            if (draft.firstReading.text.trim().isNotEmpty)
              'firstReading': double.tryParse(draft.firstReading.text.trim()),
            if (draft.secondReading.text.trim().isNotEmpty)
              'secondReading': double.tryParse(draft.secondReading.text.trim()),
            if (draft.thirdReading.text.trim().isNotEmpty)
              'thirdReading': double.tryParse(draft.thirdReading.text.trim()),
            'inspectionStatusTire': _setupRules!
                .statusForAverage(draft.average!)!
                .apiValue,
            if (draft.note.text.trim().isNotEmpty)
              'note': draft.note.text.trim(),
          },
      ],
      if (widget.initial == null) 'vehicleId': widget.vehicleId,
    };
    try {
      final result = widget.initial == null
          ? await widget.repository.create(data)
          : await widget.repository.update(widget.initial!.id, data);
      if (mounted) Navigator.of(context).pop(result);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Object {
      if (mounted) setState(() => _error = 'No se pudo guardar la inspección.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InspectionRules? _setupRules;

  void _initializeDrafts(List<VehicleInspectionTire> tires) {
    if (_draftsInitialized) return;
    _drafts = tires.map(_TireDraft.forVehicleTire).toList();
    _draftsInitialized = true;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text(
      widget.initial == null ? 'Nueva inspección' : 'Editar inspección',
    ),
    content: SizedBox(
      width: 540,
      child: Form(
        key: _formKey,
        child: FutureBuilder<_InspectionSetup>(
          future: _setup,
          builder: (context, tireSnapshot) {
            if (widget.initial == null &&
                tireSnapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (widget.initial == null && tireSnapshot.hasError) {
              return Text(
                tireSnapshot.error is ApiException
                    ? (tireSnapshot.error! as ApiException).message
                    : 'No se pudieron cargar las llantas del vehículo.',
              );
            }
            if (widget.initial == null) {
              _initializeDrafts(tireSnapshot.data?.tires ?? const []);
            }
            final rules = tireSnapshot.data?.rules ?? _setupRules;
            _setupRules = rules;
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FormField<DateTime>(
                    validator: (_) =>
                        _date == null ? 'Selecciona la fecha' : null,
                    builder: (field) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Fecha de inspección',
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                            suffixIcon: const Icon(
                              Icons.calendar_month_outlined,
                            ),
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
                    maxLines: 3,
                    decoration: _decoration(context, 'Descripción'),
                  ),
                  const SizedBox(height: 12),
                  if (_drafts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No hay llantas disponibles en este vehículo.',
                      ),
                    )
                  else
                    for (final draft in _drafts)
                      _TireDraftFields(
                        key: ValueKey(draft.tireId),
                        draft: draft,
                        rules: rules,
                        locked: widget.initial != null,
                        onChanged: () => setState(() {}),
                      ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
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
}

class _InspectionSetup {
  const _InspectionSetup({required this.tires, required this.rules});

  final List<VehicleInspectionTire> tires;
  final InspectionRules rules;
}

class _TireDraft {
  _TireDraft({
    required this.tireId,
    required this.label,
    this.inspectionTireId,
    this.firstValue,
    this.secondValue,
    this.thirdValue,
    String? initialNote,
  }) : firstReading = TextEditingController(text: firstValue?.toString() ?? ''),
       secondReading = TextEditingController(
         text: secondValue?.toString() ?? '',
       ),
       thirdReading = TextEditingController(text: thirdValue?.toString() ?? ''),
       note = TextEditingController(text: initialNote ?? '');

  factory _TireDraft.forVehicleTire(VehicleInspectionTire tire) =>
      _TireDraft(tireId: tire.id, label: tire.displayName);

  factory _TireDraft.fromInspection(InspectionTire tire) => _TireDraft(
    tireId: tire.tireId,
    inspectionTireId: tire.id,
    label: tire.currentPosition ?? 'Llanta',
    firstValue: tire.firstReading,
    secondValue: tire.secondReading,
    thirdValue: tire.thirdReading,
    initialNote: tire.note,
  );

  final String tireId;
  final String? inspectionTireId;
  final String label;
  final double? firstValue;
  final double? secondValue;
  final double? thirdValue;
  final TextEditingController firstReading;
  final TextEditingController secondReading;
  final TextEditingController thirdReading;
  final TextEditingController note;
  bool selected = true;

  double? get average {
    final values = [
      firstReading.text,
      secondReading.text,
      thirdReading.text,
    ].map((value) => double.tryParse(value.trim())).toList();
    if (values.any((value) => value == null)) return null;
    return values.cast<double>().reduce((a, b) => a + b) / 3;
  }

  void dispose() {
    firstReading.dispose();
    secondReading.dispose();
    thirdReading.dispose();
    note.dispose();
  }
}

class _TireDraftFields extends StatelessWidget {
  const _TireDraftFields({
    super.key,
    required this.draft,
    required this.rules,
    required this.locked,
    required this.onChanged,
  });

  final _TireDraft draft;
  final InspectionRules? rules;
  final bool locked;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!locked)
                Checkbox(
                  value: draft.selected,
                  onChanged: (value) {
                    draft.selected = value ?? false;
                    onChanged();
                  },
                ),
              Expanded(
                child: Text(
                  draft.label.isEmpty ? 'Llanta' : draft.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final fields = [
                ('Medición 1', draft.firstReading),
                ('Medición 2', draft.secondReading),
                ('Medición 3', draft.thirdReading),
              ];
              final columns = constraints.maxWidth < 420 ? 1 : 3;
              final width =
                  (constraints.maxWidth - (columns - 1) * 8) / columns;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final field in fields)
                    SizedBox(
                      width: width,
                      child: TextFormField(
                        controller: field.$2,
                        onChanged: (_) => onChanged(),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: field.$1,
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                          suffixText: 'mm',
                        ),
                        validator: (value) {
                          if (!draft.selected && !locked) return null;
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return 'Requerida';
                          final number = double.tryParse(text);
                          return number == null || number < 0 || number > 30
                              ? 'Usa 0–30 mm'
                              : null;
                        },
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final average = draft.average;
              final status = average == null
                  ? null
                  : rules?.statusForAverage(average);
              return InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Resultado automático',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(
                  average == null
                      ? 'Ingresa las tres mediciones'
                      : '${status?.label ?? 'Sin regla'} · ${average.toStringAsFixed(2)} mm promedio',
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: draft.note,
            decoration: InputDecoration(
              labelText: 'Nota (opcional)',
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
