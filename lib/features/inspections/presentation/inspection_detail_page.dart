import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:rodantex_app/core/network/api_exception.dart';
import 'package:rodantex_app/features/inspections/data/inspection_repository.dart';
import 'package:rodantex_app/features/inspections/data/models/inspection.dart';
import 'package:rodantex_app/features/inspections/presentation/inspections_page.dart';

/// Detalle de una inspección con edición, eliminación y evidencia por llanta.
class InspectionDetailPage extends StatefulWidget {
  const InspectionDetailPage({
    super.key,
    required this.repository,
    required this.inspectionId,
  });

  /// Repository para cargar y modificar inspecciones.
  final InspectionRepository repository;

  /// UUID de la inspección.
  final String inspectionId;

  @override
  State<InspectionDetailPage> createState() => _InspectionDetailPageState();
}

class _InspectionDetailPageState extends State<InspectionDetailPage> {
  late Future<TireInspection> _inspection = widget.repository.getById(
    widget.inspectionId,
  );
  String? _uploadingTireId;

  Future<void> _edit(TireInspection current) async {
    final result = await showDialog<TireInspection>(
      context: context,
      builder: (_) => InspectionFormDialog(
        repository: widget.repository,
        vehicleId: current.vehicleId,
        initial: current,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _inspection = widget.repository.getById(widget.inspectionId);
      });
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar inspección'),
        content: const Text('¿Quieres eliminar esta inspección?'),
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
      await widget.repository.delete(widget.inspectionId);
      if (mounted) context.pop(true);
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  Future<void> _uploadEvidence(String tireId) async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (picked.isEmpty || !mounted) return;
    final file = picked.first;
    setState(() => _uploadingTireId = tireId);
    try {
      final bytes = await file.readAsBytes();
      final result = await widget.repository.uploadEvidence(
        inspectionId: widget.inspectionId,
        tireId: tireId,
        bytes: bytes,
        filename: file.name,
      );
      if (mounted) {
        setState(() => _inspection = Future.value(result));
        _showMessage('Evidencia cargada.');
      }
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } on Object {
      if (mounted) _showMessage('No se pudo leer o cargar el archivo.');
    } finally {
      if (mounted) setState(() => _uploadingTireId = null);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Detalle de inspección'),
      actions: [
        IconButton(
          tooltip: 'Eliminar',
          onPressed: _delete,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ),
    body: FutureBuilder<TireInspection>(
      future: _inspection,
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
                    : 'No se pudo cargar la inspección.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final inspection = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inspection.description.isEmpty
                          ? 'Inspección de llantas'
                          : inspection.description,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Chip(label: Text(inspection.dateOfInspection)),
                        Chip(label: Text(inspection.status.label)),
                      ],
                    ),
                    Text('Vehículo: ${inspection.vehicleId}'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _edit(inspection),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar inspección'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Llantas inspeccionadas (${inspection.tires.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final tire in inspection.tires)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _tireLabel(tire),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Chip(label: Text(tire.status.label)),
                        ],
                      ),
                      Text(
                        'Lecturas: ${tire.firstReading ?? '—'} / ${tire.secondReading ?? '—'} / ${tire.thirdReading ?? '—'} mm',
                      ),
                      if (tire.averageDepth != null)
                        Text('Promedio: ${tire.averageDepth} mm'),
                      if (tire.remainingPercentage != null)
                        Text('Vida restante: ${tire.remainingPercentage}%'),
                      if (tire.note?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(tire.note!),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (tire.evidenceUrl?.isNotEmpty == true)
                            const Expanded(child: Text('Evidencia adjunta'))
                          else
                            const Expanded(child: Text('Sin evidencia')),
                          TextButton.icon(
                            onPressed: _uploadingTireId == tire.tireId
                                ? null
                                : () => _uploadEvidence(tire.tireId),
                            icon: _uploadingTireId == tire.tireId
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.attach_file),
                            label: const Text('Adjuntar'),
                          ),
                        ],
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

  String _tireLabel(InspectionTire tire) {
    final position = tire.currentPosition;
    if (position != null && position.isNotEmpty) return position;
    final id = tire.tireId;
    return 'Llanta ${id.length > 8 ? id.substring(0, 8) : id}';
  }
}
