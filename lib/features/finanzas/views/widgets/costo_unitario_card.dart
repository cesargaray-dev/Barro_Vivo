// lib/features/finanzas/views/widgets/costo_unitario_card.dart
//
// Tarjeta especializada que ilustra la fórmula de costo unitario con merma prorrateada
// (HU-07 Criterio 1).

import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../models/analisis_financiero_lote.dart';
import 'finanzas_ui_helpers.dart';

class CostoUnitarioCard extends StatelessWidget {
  const CostoUnitarioCard({
    super.key,
    required this.analisis,
  });

  final AnalisisFinancieroLote analisis;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.cobaltBlue.withValues(alpha: 0.2), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cobaltBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calculate_rounded,
                    color: AppColors.cobaltBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cálculo de Costo Unitario',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.cobaltBlue,
                        ),
                      ),
                      Text(
                        'Gasto de materia prima + Merma prorrateada del lote',
                        style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Banner informativo del prorrateo artesanal
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'En el oficio de la talavera, las ${analisis.piezasUtiles} piezas útiles absorben la pérdida de las ${analisis.piezasMermadas} piezas mermadas para fijar precios reales.',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.brown.shade800,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tablero de Suma: Materia Prima + Merma Prorrateada = Costo Unitario
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Materia Prima Unitaria
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MATERIA PRIMA',
                          style: textTheme.labelSmall?.copyWith(
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          FinanzasUIHelpers.formatMonedaCorta(analisis.gastoMateriaPrimaUnitario),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${FinanzasUIHelpers.formatMonedaCorta(analisis.gastoMateriaPrimaTotal)} / ${analisis.piezasUtiles} pzas',
                          style: textTheme.labelSmall?.copyWith(color: Colors.black45, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '+',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.terracotta,
                    ),
                  ),
                ),

                // 2. Merma Prorrateada Unitaria
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.terracotta.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MERMA PRORRAT.',
                          style: textTheme.labelSmall?.copyWith(
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.terracotta,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          FinanzasUIHelpers.formatMonedaCorta(analisis.mermaProrrateadaUnitaria),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.terracotta,
                          ),
                        ),
                        Text(
                          '${FinanzasUIHelpers.formatMonedaCorta(analisis.costoMermasTotal)} / ${analisis.piezasUtiles} pzas',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.terracotta.withValues(alpha: 0.7),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '=',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cobaltBlue,
                    ),
                  ),
                ),

                // 3. Costo Unitario Total
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cobaltBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cobaltBlue.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COSTO UNIT.',
                          style: textTheme.labelSmall?.copyWith(
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cobaltBlue,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          FinanzasUIHelpers.formatMonedaCorta(analisis.costoUnitario),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.cobaltBlue,
                          ),
                        ),
                        Text(
                          'por pieza sana',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.cobaltBlue.withValues(alpha: 0.8),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Trazabilidad de piezas del lote
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Piezas iniciales: ${analisis.cantidadPiezasIniciales}',
                  style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
                Text(
                  'Mermas: ${analisis.piezasMermadas} (${FinanzasUIHelpers.formatPorcentaje(analisis.porcentajePiezasMermadas)})',
                  style: textTheme.bodySmall?.copyWith(
                    color: analisis.tieneMermas ? AppColors.terracotta : Colors.black54,
                    fontWeight: analisis.tieneMermas ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                Text(
                  'Útiles: ${analisis.piezasUtiles}',
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
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
