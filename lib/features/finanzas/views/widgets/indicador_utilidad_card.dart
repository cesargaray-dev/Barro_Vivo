// lib/features/finanzas/views/widgets/indicador_utilidad_card.dart
//
// Widget que muestra el indicador de utilidad estimada enfrentando el margen
// contra el precio de venta (HU-07 Criterio 3).
//
// Cumple accesibilidad WCAG y la identidad visual de Barro Vivo.

import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../models/analisis_financiero_lote.dart';
import 'finanzas_ui_helpers.dart';

class IndicadorUtilidadCard extends StatelessWidget {
  const IndicadorUtilidadCard({
    super.key,
    required this.analisis,
    this.onEditarPrecio,
  });

  final AnalisisFinancieroLote analisis;
  final VoidCallback? onEditarPrecio;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rentabilidad = analisis.nivelRentabilidad;
    final colorRentabilidad = FinanzasUIHelpers.colorDeRentabilidad(rentabilidad);
    final iconoRentabilidad = FinanzasUIHelpers.iconoDeRentabilidad(rentabilidad);

    final precio = analisis.precioVentaUnitario;
    final costo = analisis.costoUnitario;
    final utilidad = analisis.utilidadUnitaria;
    final margen = analisis.margenUtilidadPorcentaje;

    // Proporción visual para la barra de enfrentamiento
    final factorUtilidad = precio > 0 ? (utilidad / precio).clamp(0.0, 1.0) : 0.0;
    final factorCosto = precio > 0 ? (costo / precio).clamp(0.0, 1.0) : 1.0;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: rentabilidad.esCritico
              ? colorRentabilidad.withValues(alpha: 0.5)
              : Colors.grey.shade200,
          width: rentabilidad.esCritico ? 1.5 : 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior: Título e Indicador Chip de Rentabilidad
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Utilidad y Margen Estimado',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Enfrentamiento del precio de venta contra el costo unitario',
                        style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorRentabilidad.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorRentabilidad.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconoRentabilidad, size: 16, color: colorRentabilidad),
                      const SizedBox(width: 6),
                      Text(
                        rentabilidad.etiqueta,
                        style: textTheme.labelMedium?.copyWith(
                          color: colorRentabilidad,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tablero comparativo: Precio vs Costo = Utilidad
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  // Columna 1: Precio de Venta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRECIO VENTA',
                          style: textTheme.labelSmall?.copyWith(
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          FinanzasUIHelpers.formatMonedaCorta(precio),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.cobaltBlue,
                          ),
                        ),
                        Text(
                          'por pieza',
                          style: textTheme.labelSmall?.copyWith(color: Colors.black45),
                        ),
                      ],
                    ),
                  ),

                  // Separador de resta
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '-',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black38,
                      ),
                    ),
                  ),

                  // Columna 2: Costo Unitario
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COSTO UNIT.',
                          style: textTheme.labelSmall?.copyWith(
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          FinanzasUIHelpers.formatMonedaCorta(costo),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.terracotta,
                          ),
                        ),
                        Text(
                          'MP + merma',
                          style: textTheme.labelSmall?.copyWith(color: Colors.black45),
                        ),
                      ],
                    ),
                  ),

                  // Separador de igual
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '=',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black38,
                      ),
                    ),
                  ),

                  // Columna 3: Utilidad Unitaria
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UTILIDAD NETA',
                          style: textTheme.labelSmall?.copyWith(
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          FinanzasUIHelpers.formatMonedaCorta(utilidad),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorRentabilidad,
                          ),
                        ),
                        Text(
                          'ganancia/pza',
                          style: textTheme.labelSmall?.copyWith(color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Barra Gráfica de Enfrentamiento: Margen vs Costo
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Margen de Utilidad sobre Venta',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      FinanzasUIHelpers.formatPorcentaje(margen),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorRentabilidad,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 14,
                    child: Row(
                      children: [
                        // Porción de Costo (Terracota)
                        Expanded(
                          flex: (factorCosto * 1000).toInt().clamp(1, 1000),
                          child: Container(
                            color: AppColors.terracotta.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(width: 2),
                        // Porción de Utilidad (Verde / color rentabilidad)
                        Expanded(
                          flex: (factorUtilidad * 1000).toInt().clamp(1, 1000),
                          child: Container(
                            color: colorRentabilidad,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.terracotta.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Costo (${FinanzasUIHelpers.formatPorcentaje(precio > 0 ? (costo / precio) * 100 : 100)})',
                          style: textTheme.labelSmall?.copyWith(color: Colors.black54),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colorRentabilidad,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Utilidad (${FinanzasUIHelpers.formatPorcentaje(margen)})',
                          style: textTheme.labelSmall?.copyWith(color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Alerta o Recomendación para el Dueño
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorRentabilidad.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorRentabilidad.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(iconoRentabilidad, color: colorRentabilidad, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _generarRecomendacion(analisis),
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.black87,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (onEditarPrecio != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48, // Mínimo accesible 48 dp
                child: OutlinedButton.icon(
                  onPressed: onEditarPrecio,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.cobaltBlue, width: 1.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.tune_rounded, size: 18, color: AppColors.cobaltBlue),
                  label: const Text(
                    'Simular o Cambiar Precio de Venta',
                    style: TextStyle(
                      color: AppColors.cobaltBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _generarRecomendacion(AnalisisFinancieroLote a) {
    final margen = a.margenUtilidadPorcentaje;
    if (margen >= 45.0) {
      return 'Margen excelente (${FinanzasUIHelpers.formatPorcentaje(margen)}). '
          'Este precio genera una ganancia proyectada de ${FinanzasUIHelpers.formatMoneda(a.utilidadTotalEstimada)} '
          'con las ${a.piezasUtiles} piezas útiles del lote.';
    } else if (margen >= 25.0) {
      return 'Margen saludable (${FinanzasUIHelpers.formatPorcentaje(margen)}). '
          'Cubre materias primas y absorbe las mermas sin comprometer la economía del taller.';
    } else if (margen > 0.0) {
      final precioSugerido = a.costoUnitario / (1 - 0.35); // Para alcanzar 35%
      return 'Margen ajustado (${FinanzasUIHelpers.formatPorcentaje(margen)}). '
          'Cualquier merma adicional reducirá tu ganancia a cero. '
          'Se recomienda fijar el precio en al menos ${FinanzasUIHelpers.formatMonedaCorta(precioSugerido)} para un margen del 35%.';
    } else {
      return 'Alerta crítica: Estás vendiendo a pérdida. El costo unitario de producción '
          'es de ${FinanzasUIHelpers.formatMoneda(a.costoUnitario)}. Debes subir el precio '
          'por encima de ese valor de inmediato.';
    }
  }
}
