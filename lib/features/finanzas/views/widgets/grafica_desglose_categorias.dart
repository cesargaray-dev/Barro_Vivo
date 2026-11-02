// lib/features/finanzas/views/widgets/grafica_desglose_categorias.dart
//
// Widget de desglose visual y gráfico por categorías de costo (HU-07 Criterio 2).
// Fácil de interpretar para el dueño del taller, con barra proporcional y lista detallada.

import 'package:flutter/material.dart';

import '../../models/item_desglose_costo.dart';
import 'finanzas_ui_helpers.dart';

class GraficaDesgloseCategorias extends StatelessWidget {
  const GraficaDesgloseCategorias({
    super.key,
    required this.items,
    required this.costoTotal,
    this.titulo = 'Desglose de Costos por Categoría',
    this.subtitulo = 'Distribución del gasto entre materias primas y mermas absorbidas',
  });

  final List<ItemDesgloseCosto> items;
  final double costoTotal;
  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (items.isEmpty || costoTotal <= 0.0) {
      return Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No hay desglose de costos disponible para este lote.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200, width: 1.2),
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
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.pie_chart_outline_rounded,
                    color: Colors.blueGrey,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        subtitulo,
                        style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Gráfica de Barra Proporcional Apilada (Stacked Bar)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 18,
                child: Row(
                  children: items.map((item) {
                    final factor = (item.porcentaje / 100.0).clamp(0.01, 1.0);
                    final color = FinanzasUIHelpers.colorDeCategoria(item.categoria);
                    return Flexible(
                      flex: (factor * 1000).toInt(),
                      child: Container(
                        color: color,
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Partidas individuales desglosadas
            ...items.map((item) {
              final color = FinanzasUIHelpers.colorDeCategoria(item.categoria);
              final icon = FinanzasUIHelpers.iconoDeCategoria(item.categoria);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, size: 16, color: color),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.categoria.nombre,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          FinanzasUIHelpers.formatMonedaCorta(item.monto),
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            FinanzasUIHelpers.formatPorcentaje(item.porcentaje),
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (item.porcentaje / 100.0).clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const Divider(height: 28),

            // Total del costo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Costo Total Invertido',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  FinanzasUIHelpers.formatMoneda(costoTotal),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
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
