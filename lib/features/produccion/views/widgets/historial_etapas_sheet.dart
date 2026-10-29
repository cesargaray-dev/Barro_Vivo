// lib/features/produccion/views/widgets/historial_etapas_sheet.dart
//
// Modal para consultar el historial de fechas de avance de etapa de un lote – HU-05.
// Cumple Criterio 3: "Se mantiene un historial consultable de las fechas en las
// que el lote avanzó de etapa."

import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../models/etapa_produccion.dart';
import '../../models/lote_produccion.dart';
import 'etapa_badge.dart';

/// Modal inferior que presenta la bitácora y línea de tiempo del lote.
class HistorialEtapasSheet extends StatelessWidget {
  const HistorialEtapasSheet({
    super.key,
    required this.lote,
  });

  final LoteProduccion lote;

  static Future<void> show(BuildContext context, LoteProduccion lote) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HistorialEtapasSheet(lote: lote),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final historial = lote.historial;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de arrastre superior
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Encabezado del Lote
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: lote.etapaActual.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.history_edu_rounded,
                  color: lote.etapaActual.color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
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
                    const SizedBox(height: 4),
                    Text(
                      '${lote.cantidadPiezas} piezas · Creado el ${_formatearFechaCorta(lote.fechaCreacion)}',
                      style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              EtapaBadge(etapa: lote.etapaActual),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Título de la bitácora
          Row(
            children: [
              const Icon(
                Icons.timeline_rounded,
                size: 18,
                color: AppColors.cobaltBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Línea de tiempo de las 5 etapas del oficio',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Lista de las 5 etapas con su estado y fecha
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: EtapaProduccion.values.length,
              separatorBuilder: (_, __) => const SizedBox(height: 0),
              itemBuilder: (context, index) {
                final etapa = EtapaProduccion.values[index];
                final esActual = etapa == lote.etapaActual;
                final yaPaso = etapa.orden < lote.etapaActual.orden;
                final esFutura = etapa.orden > lote.etapaActual.orden;

                // Buscar hito correspondiente en el historial
                final hito = historial.cast<dynamic>().firstWhere(
                      (h) => h.etapa == etapa,
                      orElse: () => null,
                    );

                final fechaRegistro = hito?.fecha ?? (esActual ? lote.updatedAt ?? lote.fechaCreacion : null);
                final notas = hito?.notas;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Columna del ícono y línea conectora
                      SizedBox(
                        width: 36,
                        child: Column(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: esActual
                                    ? etapa.color
                                    : (yaPaso ? AppColors.cobaltBlue : Colors.grey.shade100),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: esActual
                                      ? etapa.color
                                      : (yaPaso ? AppColors.cobaltBlue : Colors.grey.shade300),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                yaPaso
                                    ? Icons.check_rounded
                                    : (esActual ? etapa.icono : Icons.circle_outlined),
                                size: 16,
                                color: (yaPaso || esActual)
                                    ? Colors.white
                                    : Colors.grey.shade400,
                              ),
                            ),
                            if (index < EtapaProduccion.values.length - 1)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: yaPaso
                                      ? AppColors.cobaltBlue
                                      : Colors.grey.shade300,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Detalle de la etapa
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: esActual
                                  ? etapa.color.withValues(alpha: 0.06)
                                  : (yaPaso ? Colors.white : Colors.grey.shade50),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: esActual
                                    ? etapa.color.withValues(alpha: 0.3)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${etapa.orden}. ${etapa.titulo}',
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: esActual
                                            ? etapa.color
                                            : (yaPaso ? Colors.black87 : Colors.grey.shade600),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (esActual)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: etapa.color,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          'ETAPA ACTUAL',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    if (yaPaso)
                                      const Text(
                                        '✓ Completada',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    if (esFutura)
                                      Text(
                                        'Pendiente',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                // Fecha registrada del avance
                                if (fechaRegistro != null) ...[
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.event_available_rounded,
                                        size: 13,
                                        color: Colors.black54,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Fecha: ${_formatearFechaLarga(fechaRegistro)}',
                                        style: textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                ],

                                // Notas u observaciones
                                if (notas != null && notas.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.notes_rounded,
                                          size: 12,
                                          color: Colors.black54,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            notas,
                                            style: textTheme.bodySmall?.copyWith(
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (esFutura) ...[
                                  Text(
                                    etapa.descripcion,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade500,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Botón cerrar
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Cerrar Historial'),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatearFechaCorta(DateTime f) {
    final d = f.day.toString().padLeft(2, '0');
    final m = f.month.toString().padLeft(2, '0');
    final y = f.year;
    return '$d/$m/$y';
  }

  static String _formatearFechaLarga(DateTime f) {
    const meses = [
      '',
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    final mes = f.month >= 1 && f.month <= 12 ? meses[f.month] : '';
    final hora = f.hour.toString().padLeft(2, '0');
    final min = f.minute.toString().padLeft(2, '0');
    return '${f.day} de $mes de ${f.year} ($hora:$min hrs)';
  }
}
