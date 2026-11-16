// lib/features/catalogo/views/widgets/pieza_catalogo_card.dart
//
// Tarjeta comercial para cada pieza terminada con existencia en el catálogo (HU-08).

import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../models/pieza_catalogo.dart';
import 'catalogo_ui_helpers.dart';

class PiezaCatalogoCard extends StatelessWidget {
  const PiezaCatalogoCard({
    super.key,
    required this.pieza,
    required this.cantidadEnCarrito,
    required this.onAgregar,
    required this.onIncrementar,
    required this.onDecrementar,
  });

  final PiezaCatalogo pieza;
  final int cantidadEnCarrito;
  final VoidCallback onAgregar;
  final VoidCallback onIncrementar;
  final VoidCallback onDecrementar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final catColor = CatalogoUIHelpers.colorCategoria(pieza.categoria);
    final catIcon = CatalogoUIHelpers.iconoCategoria(pieza.categoria);
    final puedeMas = cantidadEnCarrito < pieza.existencia;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: cantidadEnCarrito > 0
              ? AppColors.cobaltBlue.withValues(alpha: 0.45)
              : Colors.grey.shade200,
          width: cantidadEnCarrito > 0 ? 1.5 : 1,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con icono, categoría y badges de etapa/stock
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(catIcon, color: catColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pieza.nombre,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _Badge(
                            texto: pieza.categoria,
                            fondo: catColor.withValues(alpha: 0.1),
                            colorTexto: catColor,
                          ),
                          _Badge(
                            texto: 'Etapa: ${pieza.etapaActual.titulo}',
                            fondo: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                            colorTexto: const Color(0xFF2E7D32),
                            icono: Icons.verified_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              pieza.descripcion,
              style: textTheme.bodySmall?.copyWith(
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // Fila de precio unitario, lote y existencia disponible
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PRECIO UNITARIO',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${CatalogoUIHelpers.formatMoneda(pieza.precioUnitario)} MXN',
                        style: textTheme.titleLarge?.copyWith(
                          color: AppColors.cobaltBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        pieza.loteCodigo,
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.black45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Existencia: ${pieza.existencia} pzas',
                        style: textTheme.labelMedium?.copyWith(
                          color: pieza.existencia <= 4
                              ? AppColors.terracotta
                              : const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Acción de carrito con altura mínima de 48 dp
            if (cantidadEnCarrito == 0)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onAgregar,
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text('Agregar al carrito'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cobaltBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            else
              Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: onDecrementar,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 48),
                      ),
                      child: const Icon(Icons.remove_rounded),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'En carrito: $cantidadEnCarrito',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.cobaltBlue,
                          ),
                        ),
                        Text(
                          'Subtotal: ${CatalogoUIHelpers.formatMoneda(pieza.precioUnitario * cantidadEnCarrito)}',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: puedeMas ? onIncrementar : null,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 48),
                        backgroundColor: AppColors.cobaltBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Icon(Icons.add_rounded),
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

class _Badge extends StatelessWidget {
  const _Badge({
    required this.texto,
    required this.fondo,
    required this.colorTexto,
    this.icono,
  });

  final String texto;
  final Color fondo;
  final Color colorTexto;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 13, color: colorTexto),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorTexto,
            ),
          ),
        ],
      ),
    );
  }
}

