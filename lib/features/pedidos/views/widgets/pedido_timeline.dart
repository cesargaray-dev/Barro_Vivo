// lib/features/pedidos/views/widgets/pedido_timeline.dart
//
// Línea de tiempo visual de los 5 estados del pedido (HU-09 Criterio 2):
// En espera de pago -> Pagado -> En preparación -> Enviado -> Entregado.

import 'package:flutter/material.dart';

import '../../models/estado_pedido.dart';
import '../../models/pedido.dart';
import 'pedidos_ui_helpers.dart';

class PedidoTimeline extends StatelessWidget {
  const PedidoTimeline({
    super.key,
    required this.pedido,
  });

  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final estados = EstadoPedido.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seguimiento del pedido',
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(estados.length, (index) {
          final estado = estados[index];
          final esUltimo = index == estados.length - 1;
          final alcanzado = pedido.estadoCompletado(estado);
          final esActual = pedido.estadoActual == estado;
          final fecha = pedido.fechaDeEstado(estado);
          final colorEstado = PedidosUIHelpers.colorEstado(estado);

          final Color colorNodo =
              alcanzado ? colorEstado : Colors.grey.shade300;
          final Color colorIcono =
              alcanzado ? Colors.white : Colors.grey.shade500;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Columna izquierda: círculo + línea conectora
                SizedBox(
                  width: 34,
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: colorNodo,
                          shape: BoxShape.circle,
                          border: esActual
                              ? Border.all(
                                  color: colorEstado.withValues(alpha: 0.35),
                                  width: 4,
                                )
                              : null,
                        ),
                        child: Icon(
                          PedidosUIHelpers.iconoEstado(estado),
                          size: 15,
                          color: colorIcono,
                        ),
                      ),
                      if (!esUltimo)
                        Expanded(
                          child: Container(
                            width: 2.5,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            color: pedido.estadoActual.orden > estado.orden
                                ? colorEstado.withValues(alpha: 0.7)
                                : Colors.grey.shade300,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Columna derecha: título, badge actual, fecha y descripción
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: esUltimo ? 0 : 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              estado.titulo,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight:
                                    alcanzado ? FontWeight.w700 : FontWeight.w500,
                                color: alcanzado ? Colors.black87 : Colors.black45,
                              ),
                            ),
                            if (esActual)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorEstado.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'ESTADO ACTUAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: colorEstado,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (fecha != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            PedidosUIHelpers.formatFecha(fecha),
                            style: textTheme.labelSmall?.copyWith(
                              color: colorEstado,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (esActual) ...[
                          const SizedBox(height: 3),
                          Text(
                            estado.descripcion,
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

