// lib/features/finanzas/views/widgets/lote_financiero_card.dart
//
// Tarjeta de resumen financiero individual para un lote de producción (HU-07).
//
// Muestra costo unitario, mermas, precio de venta, margen e indicador de rentabilidad.
// Cumple con accesibilidad de 48 dp en todos sus elementos interactivos.

import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../models/analisis_financiero_lote.dart';
import '../../../produccion/views/widgets/etapa_badge.dart';
import 'finanzas_ui_helpers.dart';
import 'simulador_precio_dialog.dart';

class LoteFinancieroCard extends StatelessWidget {
  const LoteFinancieroCard({
    super.key,
    required this.analisis,
    required this.onVerDetalle,
  });

  final AnalisisFinancieroLote analisis;
  final VoidCallback onVerDetalle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rentabilidad = analisis.nivelRentabilidad;
    final colorRentabilidad = FinanzasUIHelpers.colorDeRentabilidad(rentabilidad);
    final iconoRentabilidad = FinanzasUIHelpers.iconoDeRentabilidad(rentabilidad);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: rentabilidad.esCritico
              ? colorRentabilidad.withValues(alpha: 0.4)
              : Colors.grey.shade200,
          width: rentabilidad.esCritico ? 1.5 : 1,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado: Código y Etapa de Producción
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analisis.loteCodigo,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      if (analisis.descripcion != null && analisis.descripcion!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          analisis.descripcion!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                        ),
                      ],
                    ],
                  ),
                ),
                EtapaBadge(etapa: analisis.etapaActual),
              ],
            ),
            const SizedBox(height: 14),

            // Tablero de métricas del lote
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  // Piezas útiles y mermas
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PIEZAS',
                          style: textTheme.labelSmall?.copyWith(
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${analisis.piezasUtiles} útiles',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        if (analisis.tieneMermas)
                          Text(
                            '${analisis.piezasMermadas} mermadas',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.terracotta,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          Text(
                            '0 mermas',
                            style: textTheme.labelSmall?.copyWith(color: Colors.black45),
                          ),
                      ],
                    ),
                  ),

                  // Costo unitario (MP + merma)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COSTO UNIT.',
                          style: textTheme.labelSmall?.copyWith(
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          FinanzasUIHelpers.formatMonedaCorta(analisis.costoUnitario),
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.terracotta,
                          ),
                        ),
                        Text(
                          analisis.tieneMermas ? 'c/merma prorrat.' : 'sin mermas',
                          style: textTheme.labelSmall?.copyWith(color: Colors.black45),
                        ),
                      ],
                    ),
                  ),

                  // Precio de venta sugerido
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRECIO VENTA',
                          style: textTheme.labelSmall?.copyWith(
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          FinanzasUIHelpers.formatMonedaCorta(analisis.precioVentaUnitario),
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.cobaltBlue,
                          ),
                        ),
                        Text(
                          'al público',
                          style: textTheme.labelSmall?.copyWith(color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Fila de Utilidad y Margen (Wrap adaptable para prevenir desbordamientos en pantallas estrechas)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorRentabilidad.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorRentabilidad.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconoRentabilidad, size: 14, color: colorRentabilidad),
                      const SizedBox(width: 5),
                      Text(
                        '${rentabilidad.etiqueta}: Margen ${FinanzasUIHelpers.formatPorcentaje(analisis.margenUtilidadPorcentaje)}',
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorRentabilidad,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Ganancia: ${FinanzasUIHelpers.formatMonedaCorta(analisis.utilidadUnitaria)}/pza',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorRentabilidad,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Botones de acción accesibles (mínimo 48 dp)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: onVerDetalle,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.analytics_outlined, size: 18, color: Colors.black87),
                      label: const Text(
                        'Ver Desglose',
                        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => SimuladorPrecioDialog.show(context, analisis),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cobaltBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.attach_money_rounded, size: 18),
                      label: const Text(
                        'Fijar Precio',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
