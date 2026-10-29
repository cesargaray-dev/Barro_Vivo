// lib/features/produccion/views/widgets/avanzar_etapa_dialog.dart
//
// Diálogo de confirmación para avanzar de etapa en un lote – HU-05.
//
// Restringe el movimiento únicamente a la siguiente etapa estricta de las 5:
// barro crudo -> jahuete -> esmaltado -> decorado -> terminado.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../models/etapa_produccion.dart';
import '../../models/lote_produccion.dart';
import '../../viewmodels/produccion_viewmodel.dart';
import 'etapa_badge.dart';

/// Diálogo modal que confirma y registra la fecha de avance hacia la siguiente etapa estricta.
class AvanzarEtapaDialog extends StatefulWidget {
  const AvanzarEtapaDialog({
    super.key,
    required this.lote,
  });

  final LoteProduccion lote;

  static Future<bool?> show(BuildContext context, LoteProduccion lote) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AvanzarEtapaDialog(lote: lote),
    );
  }

  @override
  State<AvanzarEtapaDialog> createState() => _AvanzarEtapaDialogState();
}

class _AvanzarEtapaDialogState extends State<AvanzarEtapaDialog> {
  late DateTime _fechaAvance;
  final TextEditingController _notasController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fechaAvance = DateTime.now();
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaAvance,
      firstDate: widget.lote.fechaCreacion,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Fecha del avance de etapa',
      confirmText: 'Seleccionar',
      cancelText: 'Cancelar',
    );

    if (seleccionada != null) {
      setState(() {
        _fechaAvance = DateTime(
          seleccionada.year,
          seleccionada.month,
          seleccionada.day,
          _fechaAvance.hour,
          _fechaAvance.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final proximaEtapa = widget.lote.siguienteEtapa;

    if (proximaEtapa == null) {
      return AlertDialog(
        title: const Text('Lote completado'),
        content: const Text(
          'Este lote ya se encuentra en la etapa final ("Terminado") y no puede avanzar más.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Entendido'),
          ),
        ],
      );
    }

    final vm = context.watch<ProduccionViewModel>();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: proximaEtapa.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(proximaEtapa.icono, color: proximaEtapa.color, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Avanzar de Etapa',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lote: ${widget.lote.codigo} (${widget.lote.cantidadPiezas} piezas)',
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 14),

            // Comparativa Etapa Actual -> Próxima Etapa Estricta
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Etapa actual',
                            style: TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                          const SizedBox(height: 4),
                          EtapaBadge(etapa: widget.lote.etapaActual, compact: true),
                        ],
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.cobaltBlue,
                        size: 22,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Siguiente etapa estricta',
                            style: TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                          const SizedBox(height: 4),
                          EtapaBadge(etapa: proximaEtapa, compact: true),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    proximaEtapa.descripcion,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Selector de Fecha de Avance
            const Text(
              'Fecha de este avance:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _seleccionarFecha,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.cobaltBlue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _formatearFecha(_fechaAvance),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    Text(
                      'Cambiar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: proximaEtapa.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Notas opcionales
            const Text(
              'Observaciones del artesano (opcional):',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notasController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Ej: Horneado a 900°C en horno de leña...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: vm.isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: vm.isSaving
              ? null
              : () async {
                  final exito = await context.read<ProduccionViewModel>().avanzarEtapa(
                        loteId: widget.lote.id,
                        fecha: _fechaAvance,
                        notas: _notasController.text.trim().isNotEmpty
                            ? _notasController.text.trim()
                            : null,
                      );

                  if (context.mounted) {
                    if (exito) {
                      Navigator.of(context).pop(true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '¡Lote "${widget.lote.codigo}" avanzó exitosamente a ${proximaEtapa.titulo}!',
                          ),
                          backgroundColor: proximaEtapa.color,
                        ),
                      );
                    } else if (vm.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(vm.errorMessage!),
                          backgroundColor: AppColors.terracotta,
                        ),
                      );
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: proximaEtapa.color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: vm.isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text('Avanzar a ${proximaEtapa.titulo}'),
        ),
      ],
    );
  }

  String _formatearFecha(DateTime f) {
    final d = f.day.toString().padLeft(2, '0');
    final m = f.month.toString().padLeft(2, '0');
    final y = f.year;
    return '$d/$m/$y';
  }
}
