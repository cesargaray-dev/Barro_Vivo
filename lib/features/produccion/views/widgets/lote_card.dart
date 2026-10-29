// lib/features/produccion/views/widgets/lote_card.dart
//
// Tarjeta de lote de producción con indicador de las 5 etapas – HU-05.
//
// Permite:
//   – Ver el estado y progreso en las cinco etapas estrictas del oficio.
//   – Avanzar a la siguiente etapa inmediata (Criterio 2).
//   – Consultar el historial de fechas de avance (Criterio 3).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../models/lote_produccion.dart';
import '../../viewmodels/produccion_viewmodel.dart';
import 'avanzar_etapa_dialog.dart';
import 'etapa_badge.dart';
import 'etapa_progress_indicator.dart';
import 'historial_etapas_sheet.dart';

/// Tarjeta visual que representa un lote de producción y sus acciones.
class LoteCard extends StatelessWidget {
  const LoteCard({
    super.key,
    required this.lote,
  });

  final LoteProduccion lote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final etapa = lote.etapaActual;
    final puedeAvanzar = lote.puedeAvanzar;
    final proximaEtapa = lote.siguienteEtapa;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: lote.estaTerminado
              ? Colors.green.shade200
              : AppColors.cobaltBlue.withValues(alpha: 0.15),
          width: 1.2,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior: Código, Badge de Piezas y Menú
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lote.codigo,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.cobaltBlue,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Iniciado el ${_formatearFecha(lote.fechaCreacion)}',
                        style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cobaltBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.widgets_outlined, size: 14, color: AppColors.cobaltBlue),
                      const SizedBox(width: 4),
                      Text(
                        '${lote.cantidadPiezas} pzas',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cobaltBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.black45),
                  padding: EdgeInsets.zero,
                  onSelected: (opcion) {
                    if (opcion == 'baja') {
                      _confirmarBaja(context);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'baja',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Dar de baja lote', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Descripción si existe
            if (lote.descripcion != null && lote.descripcion!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                lote.descripcion!,
                style: textTheme.bodyMedium?.copyWith(color: Colors.black87),
              ),
            ],
            const SizedBox(height: 16),

            // Indicador de Progreso de las 5 Etapas
            EtapaProgressIndicator(etapaActual: etapa),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Fila inferior: Badge de etapa actual y Botones de Acción
            Row(
              children: [
                EtapaBadge(etapa: etapa),
                const Spacer(),

                // Botón: Ver Historial (Criterio 3)
                OutlinedButton.icon(
                  onPressed: () => HistorialEtapasSheet.show(context, lote),
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text('Historial', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 8),

                // Botón: Avanzar a Siguiente Etapa (Criterio 2)
                if (puedeAvanzar && proximaEtapa != null)
                  ElevatedButton.icon(
                    onPressed: () => AvanzarEtapaDialog.show(context, lote),
                    icon: Icon(proximaEtapa.icono, size: 16),
                    label: Text(
                      'A ${proximaEtapa.titulo}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: proximaEtapa.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Terminado',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarBaja(BuildContext context) {
    showDialog(
      context: context,
      builder: (dlgContext) => AlertDialog(
        title: const Text('¿Dar de baja este lote?'),
        content: Text(
          'El lote "${lote.codigo}" dejará de mostrarse en la lista activa de producción.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dlgContext).pop();
              await context.read<ProduccionViewModel>().darDeBajaLote(lote.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Dar de baja'),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(DateTime f) {
    final d = f.day.toString().padLeft(2, '0');
    final m = f.month.toString().padLeft(2, '0');
    final y = f.year;
    return '$d/$m/$y';
  }
}
