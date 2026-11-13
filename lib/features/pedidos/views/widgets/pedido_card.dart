// lib/features/pedidos/views/widgets/pedido_card.dart
//
// Tarjeta de pedido con folio consecutivo, partidas, total y línea de tiempo (HU-09).

import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../models/pedido.dart';
import 'pedido_timeline.dart';
import 'pedidos_ui_helpers.dart';

class PedidoCard extends StatelessWidget {
  const PedidoCard({
    super.key,
    required this.pedido,
    this.esVistaTaller = false,
    this.onAvanzarEstado,
    this.isProcessing = false,
  });

  final Pedido pedido;
  final bool esVistaTaller;
  final VoidCallback? onAvanzarEstado;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorEstado = PedidosUIHelpers.colorEstado(pedido.estadoActual);
    final siguiente = pedido.siguienteEstado;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colorEstado.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado: Folio BV-XXXX y Estado actual
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Folio ${pedido.folio}',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.cobaltBlue,
                      ),
                    ),
                    Text(
                      'Emitido: ${PedidosUIHelpers.formatFecha(pedido.fechaCreacion)}',
                      style: textTheme.labelSmall?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorEstado.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PedidosUIHelpers.iconoEstado(pedido.estadoActual),
                        size: 16,
                        color: colorEstado,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        pedido.estadoActual.titulo,
                        style: textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorEstado,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (esVistaTaller) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cliente: ${pedido.clienteNombre?.isNotEmpty == true ? pedido.clienteNombre : pedido.clienteEmail}',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    if (pedido.direccionEntrega != null &&
                        pedido.direccionEntrega!.isNotEmpty)
                      Text(
                        'Entrega: ${pedido.direccionEntrega}',
                        style: textTheme.labelSmall?.copyWith(color: Colors.black54),
                      ),
                  ],
                ),
              ),
            ],

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),

            // Detalle resumido de piezas
            ...pedido.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.cantidad}x ${item.nombrePieza}',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      PedidosUIHelpers.formatMoneda(item.subtotal),
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cobaltBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total del pedido (${pedido.totalPiezas} ${pedido.totalPiezas == 1 ? 'pieza' : 'piezas'})',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${PedidosUIHelpers.formatMoneda(pedido.total)} MXN',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.cobaltBlue,
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1),
            ),

            // Línea de tiempo completa (HU-09 Criterio 2)
            PedidoTimeline(pedido: pedido),

            if (esVistaTaller && siguiente != null && onAvanzarEstado != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: isProcessing ? null : onAvanzarEstado,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text('Avanzar a: ${siguiente.titulo}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PedidosUIHelpers.colorEstado(siguiente),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

