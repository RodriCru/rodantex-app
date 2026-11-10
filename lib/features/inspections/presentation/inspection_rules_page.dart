import 'package:flutter/material.dart';

import 'package:rodantex_app/core/network/api_exception.dart';
import 'package:rodantex_app/features/inspections/data/inspection_repository.dart';
import 'package:rodantex_app/features/inspections/data/models/inspection.dart';
import 'package:rodantex_app/features/inspections/data/models/inspection_rules.dart';

/// Consulta, guarda y restablece umbrales por tipo de vehículo.
class InspectionRulesPage extends StatefulWidget {
  const InspectionRulesPage({super.key, required this.repository});

  /// Repository de la API de reglas.
  final InspectionRepository repository;

  @override
  State<InspectionRulesPage> createState() => _InspectionRulesPageState();
}

class _InspectionRulesPageState extends State<InspectionRulesPage> {
  static const _carTypes = ['SEDAN', 'SUV', 'PICKUP', 'VAN', 'TRUCK'];
  static const _statuses = [
    InspectionTireStatus.optimal,
    InspectionTireStatus.changeRequired,
    InspectionTireStatus.needsDisassembly,
    InspectionTireStatus.needsImmediateDisassembly,
    InspectionTireStatus.inspectionImpossible,
    InspectionTireStatus.danger,
  ];

  String _carType = 'SEDAN';
  Future<InspectionRules>? _rulesFuture;
  String? _loadedType;
  final Map<InspectionTireStatus, TextEditingController> _fields = {};
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _rulesFuture = widget.repository.getRules(carType: _carType);
  }

  void _load() {
    _disposeFields();
    _loadedType = null;
    _message = null;
    _rulesFuture = widget.repository.getRules(carType: _carType);
  }

  void _seed(InspectionRules rules) {
    if (_loadedType == _carType) return;
    _disposeFields();
    for (final status in _statuses) {
      InspectionRule? rule;
      for (final candidate in rules.rules) {
        if (candidate.status == status) {
          rule = candidate;
          break;
        }
      }
      _fields[status] = TextEditingController(
        text: rule == null ? '' : _numberText(rule.maxDepthMm),
      );
    }
    _loadedType = _carType;
  }

  String _numberText(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();

  void _disposeFields() {
    for (final field in _fields.values) {
      field.dispose();
    }
    _fields.clear();
  }

  @override
  void dispose() {
    _disposeFields();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final rules = [
        for (final status in _statuses)
          InspectionRule(
            status: status,
            maxDepthMm: double.parse(_fields[status]!.text.trim()),
          ),
      ];
      await widget.repository.saveRules(carType: _carType, rules: rules);
      if (mounted) {
        setState(() {
          _message = 'Reglas guardadas.';
          _messageIsError = false;
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _message = error.message;
          _messageIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restablecer reglas'),
        content: Text('Se restablecerán las reglas para $_carType.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.resetRules(carType: _carType);
      if (mounted) {
        setState(() {
          _message = 'Reglas restablecidas.';
          _messageIsError = false;
        });
        _load();
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _message = error.message;
          _messageIsError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reglas de inspección')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          initialValue: _carType,
          decoration: InputDecoration(
            labelText: 'Tipo de vehículo',
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          items: [
            for (final type in _carTypes)
              DropdownMenuItem(value: type, child: Text(type)),
          ],
          onChanged: _saving
              ? null
              : (value) {
                  if (value == null) return;
                  setState(() {
                    _carType = value;
                    _load();
                  });
                },
        ),
        const SizedBox(height: 12),
        FutureBuilder<InspectionRules>(
          future: _rulesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  Text(
                    snapshot.error is ApiException
                        ? (snapshot.error! as ApiException).message
                        : 'No se pudieron cargar las reglas.',
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: () => setState(_load),
                    child: const Text('Reintentar'),
                  ),
                ],
              );
            }
            final rules = snapshot.data;
            if (rules == null) return const SizedBox.shrink();
            _seed(rules);
            return Form(
              key: _formKey,
              child: Column(
                children: [
                  if (rules.source.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('Configuración: ${rules.source}'),
                      ),
                    ),
                  for (final status in _statuses)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        controller: _fields[status],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: status.label,
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                          suffixText: 'mm',
                        ),
                        validator: (value) {
                          final parsed = double.tryParse(value?.trim() ?? '');
                          return parsed == null || parsed < 0
                              ? 'Ingresa una profundidad válida'
                              : null;
                        },
                      ),
                    ),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _messageIsError
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : _reset,
                          child: const Text('Restablecer'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ),
  );
}
