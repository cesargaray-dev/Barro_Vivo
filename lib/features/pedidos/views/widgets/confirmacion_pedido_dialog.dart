// lib/features/pedidos/views/widgets/confirmacion_pedido_dialog.dart
//
// Diálogo de confirmación que muestra el folio consecutivo emitido (ej. BV-0128)
// y el estado inicial "En espera de pago" (HU-09 Criterio 1).

import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../models/pedido.dart';
import 'pedidos_ui_helpers.dart';

class ConfirmacionPedidoDialog extends StatelessWidget {
  const ConfirmacionPedidoDialog({
    super.key,
    required this.pedido,
    required this.onVerMisPedidos,
  });

  final Pedido pedido;
  final VoidCallback onVerMisPedidos;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF2E7D32),
              size: 40,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pedido Confirmado',
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.cobaltBlue,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tu orden fue registrada y enviada a la bandeja del taller artesanal.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cobaltBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.cobaltBlue.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'FOLIO ASIGNADO',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pedido.folio,
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.cobaltBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: PedidosUIHelpers.colorEstado(pedido.estadoActual)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Estado inicial: ${pedido.estadoActual.titulo}',
                    style: textTheme.labelMedium?.copyWith(
                      color: PedidosUIHelpers.colorEstado(pedido.estadoActual),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: ${PedidosUIHelpers.formatMoneda(pedido.total)} MXN',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onVerMisPedidos();
            },
            icon: const Icon(Icons.timeline_rounded),
            label: const Text('Ver en Mis Pedidos'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Seguir comprando'),
          ),
        ),
      ],
    );
  }
}

