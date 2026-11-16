// lib/features/catalogo/views/widgets/resumen_totales_carrito_card.dart
//
// Tarjeta de resumen explícito de totales del carrito antes de proceder al pago (HU-08 Criterio 2).

import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../models/resumen_carrito.dart';
import 'catalogo_ui_helpers.dart';

class ResumenTotalesCarritoCard extends StatelessWidget {
  const ResumenTotalesCarritoCard({
    super.key,
    required this.resumen,
    required this.onProcederAlPago,
    this.isProcessing = false,
  });

  final ResumenCarrito resumen;
  final VoidCallback? onProcederAlPago;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: AppColors.cobaltBlue.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.cobaltBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Resumen de Totales',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.cobaltBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _FilaTotal(
              etiqueta: 'Artículos en carrito',
              valor:
                  '${resumen.totalPartidas} ${resumen.totalPartidas == 1 ? 'producto' : 'productos'} (${resumen.totalPiezas} ${resumen.totalPiezas == 1 ? 'pieza' : 'piezas'})',
            ),
            const SizedBox(height: 8),
            _FilaTotal(
              etiqueta: 'Subtotal de piezas',
              valor: '${CatalogoUIHelpers.formatMoneda(resumen.subtotalProductos)} MXN',
            ),
            const SizedBox(height: 8),
            _FilaTotal(
              etiqueta: 'Embalaje y envío asegurado',
              valor: resumen.tieneEnvioGratis
                  ? 'Gratis'
                  : '${CatalogoUIHelpers.formatMoneda(resumen.costoEnvio)} MXN',
              colorValor:
                  resumen.tieneEnvioGratis ? const Color(0xFF2E7D32) : Colors.black87,
            ),

            if (!resumen.estaVacio && !resumen.tieneEnvioGratis) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.terracotta.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_shipping_outlined,
                      size: 16,
                      color: AppColors.terracotta,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Te faltan ${CatalogoUIHelpers.formatMoneda(resumen.faltanteParaEnvioGratis)} para envío gratis (compras desde ${CatalogoUIHelpers.formatMoneda(ResumenCarrito.umbralEnvioGratis)}).',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.terracotta,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total a pagar',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${CatalogoUIHelpers.formatMoneda(resumen.totalAPagar)} MXN',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.cobaltBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed:
                    (resumen.estaVacio || isProcessing) ? null : onProcederAlPago,
                icon: isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  isProcessing ? 'Confirmando pedido...' : 'Confirmar pedido',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaTotal extends StatelessWidget {
  const _FilaTotal({
    required this.etiqueta,
    required this.valor,
    this.colorValor,
  });

  final String etiqueta;
  final String valor;
  final Color? colorValor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            etiqueta,
            style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          valor,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorValor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

