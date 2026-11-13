// lib/features/pedidos/models/historial_estado_pedido.dart
//
// Registro de cambio de estado dentro de la línea de tiempo de un pedido (HU-09).

import 'estado_pedido.dart';

/// Evento histórico de transición de estado de un pedido.
class HistorialEstadoPedido {
  const HistorialEstadoPedido({
    required this.id,
    required this.pedidoId,
    required this.estado,
    required this.fecha,
    this.nota,
  });

  final String id;
  final String pedidoId;
  final EstadoPedido estado;
  final DateTime fecha;
  final String? nota;

  factory HistorialEstadoPedido.fromJson(Map<String, dynamic> json) {
    return HistorialEstadoPedido(
      id: json['id'] as String? ?? '',
      pedidoId: json['pedido_id'] as String? ?? '',
      estado: EstadoPedido.fromCodigo(json['estado'] as String?),
      fecha: json['fecha'] != null
          ? DateTime.tryParse(json['fecha'].toString()) ?? DateTime.now()
          : DateTime.now(),
      nota: json['nota'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pedido_id': pedidoId,
        'estado': estado.codigo,
        'fecha': fecha.toIso8601String(),
        if (nota != null && nota!.isNotEmpty) 'nota': nota,
      };
}

