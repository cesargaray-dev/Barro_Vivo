// lib/features/pedidos/models/pedido.dart
//
// Entidad de dominio de Pedido con folio consecutivo e historial de estados (HU-09).
//
// Criterios de aceptación cubiertos:
//   1. Al confirmar la compra emite un folio consecutivo visible (ej. BV-0128).
//   2. Soporta la línea de tiempo de estados:
//      en espera de pago -> pagado -> en preparación -> enviado -> entregado.

import 'estado_pedido.dart';
import 'historial_estado_pedido.dart';
import 'item_pedido.dart';

/// Excepción base para operaciones del módulo de pedidos.
class PedidoException implements Exception {
  const PedidoException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Excepción al intentar confirmar una compra con el carrito vacío.
class CarritoVacioException extends PedidoException {
  const CarritoVacioException()
      : super('Agrega al menos una pieza al carrito antes de confirmar el pedido.');
}

/// Excepción cuando se intenta avanzar un pedido ya entregado o a un estado inválido.
class TransicionEstadoPedidoInvalidaException extends PedidoException {
  const TransicionEstadoPedidoInvalidaException(super.message);
}

/// Entidad inmutable que representa un pedido del cliente y su seguimiento en el taller.
class Pedido {
  const Pedido({
    required this.id,
    required this.folio,
    required this.numeroConsecutivo,
    required this.clienteEmail,
    required this.estadoActual,
    required this.items,
    required this.subtotal,
    required this.costoEnvio,
    required this.total,
    required this.historialEstados,
    required this.fechaCreacion,
    this.clienteNombre,
    this.direccionEntrega,
    this.notasCliente,
    this.updatedAt,
  });

  final String id;

  /// Folio consecutivo visible al cliente y al taller (ej. "BV-0128").
  final String folio;

  /// Número entero consecutivo utilizado para generar [folio].
  final int numeroConsecutivo;

  final String clienteEmail;
  final String? clienteNombre;
  final String? direccionEntrega;
  final String? notasCliente;

  final EstadoPedido estadoActual;
  final List<ItemPedido> items;
  final double subtotal;
  final double costoEnvio;
  final double total;
  final List<HistorialEstadoPedido> historialEstados;
  final DateTime fechaCreacion;
  final DateTime? updatedAt;

  /// Formatea el número consecutivo al estándar de Barro Vivo (ej. 128 -> "BV-0128").
  static String formatearFolio(int consecutivo) {
    return 'BV-${consecutivo.toString().padLeft(4, '0')}';
  }

  /// Total de piezas físicas incluidas en el pedido.
  int get totalPiezas => items.fold<int>(0, (acc, i) => acc + i.cantidad);

  /// Indica si el pedido puede avanzar al siguiente estado de la línea de tiempo.
  bool get puedeAvanzarEstado => estadoActual.siguiente != null;

  /// Estado inmediato siguiente, o `null` si ya alcanzó "Entregado".
  EstadoPedido? get siguienteEstado => estadoActual.siguiente;

  /// Determina si [estado] ya fue alcanzado o superado en la línea de tiempo.
  bool estadoCompletado(EstadoPedido estado) => estadoActual.orden >= estado.orden;

  /// Obtiene la fecha registrada para un [estado] en el historial, si existe.
  DateTime? fechaDeEstado(EstadoPedido estado) {
    for (final entry in historialEstados) {
      if (entry.estado == estado) return entry.fecha;
    }
    return null;
  }

  /// Retorna una nueva copia del pedido habiendo avanzado al siguiente estado.
  Pedido avanzarASiguienteEstado({
    required DateTime fecha,
    String? nota,
    String? historialId,
  }) {
    final proximo = estadoActual.siguiente;
    if (proximo == null) {
      throw TransicionEstadoPedidoInvalidaException(
        'El pedido $folio ya se encuentra en estado "${estadoActual.titulo}" y no puede avanzar más.',
      );
    }

    final nuevoEvento = HistorialEstadoPedido(
      id: historialId ?? 'hist_ped_${DateTime.now().microsecondsSinceEpoch}',
      pedidoId: id,
      estado: proximo,
      fecha: fecha,
      nota: nota,
    );

    return copyWith(
      estadoActual: proximo,
      historialEstados: [...historialEstados, nuevoEvento],
      updatedAt: fecha,
    );
  }

  factory Pedido.fromJson(
    Map<String, dynamic> json, {
    List<HistorialEstadoPedido>? historialExterno,
  }) {
    final rawItems = json['items'];
    final itemsParseados = rawItems is List
        ? rawItems
            .map((e) => ItemPedido.fromJson(e as Map<String, dynamic>))
            .toList()
        : <ItemPedido>[];

    final rawHistorial = json['historial_estados'];
    final historialParseado = historialExterno ??
        (rawHistorial is List
            ? rawHistorial
                .map(
                  (e) =>
                      HistorialEstadoPedido.fromJson(e as Map<String, dynamic>),
                )
                .toList()
            : <HistorialEstadoPedido>[]);

    final consecutivo = (json['numero_consecutivo'] as num?)?.toInt() ?? 1;

    return Pedido(
      id: json['id'] as String? ?? '',
      folio: (json['folio'] as String?)?.isNotEmpty == true
          ? json['folio'] as String
          : formatearFolio(consecutivo),
      numeroConsecutivo: consecutivo,
      clienteEmail: json['cliente_email'] as String? ?? '',
      clienteNombre: json['cliente_nombre'] as String?,
      direccionEntrega: json['direccion_entrega'] as String?,
      notasCliente: json['notas_cliente'] as String?,
      estadoActual: EstadoPedido.fromCodigo(json['estado_actual'] as String?),
      items: itemsParseados,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      costoEnvio: (json['costo_envio'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      historialEstados: historialParseado,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.tryParse(json['fecha_creacion'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'folio': folio,
      'numero_consecutivo': numeroConsecutivo,
      'cliente_email': clienteEmail,
      'cliente_nombre': clienteNombre,
      'direccion_entrega': direccionEntrega,
      'notas_cliente': notasCliente,
      'estado_actual': estadoActual.codigo,
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'costo_envio': costoEnvio,
      'total': total,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  Pedido copyWith({
    String? id,
    String? folio,
    int? numeroConsecutivo,
    String? clienteEmail,
    String? clienteNombre,
    String? direccionEntrega,
    String? notasCliente,
    EstadoPedido? estadoActual,
    List<ItemPedido>? items,
    double? subtotal,
    double? costoEnvio,
    double? total,
    List<HistorialEstadoPedido>? historialEstados,
    DateTime? fechaCreacion,
    DateTime? updatedAt,
  }) {
    return Pedido(
      id: id ?? this.id,
      folio: folio ?? this.folio,
      numeroConsecutivo: numeroConsecutivo ?? this.numeroConsecutivo,
      clienteEmail: clienteEmail ?? this.clienteEmail,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      direccionEntrega: direccionEntrega ?? this.direccionEntrega,
      notasCliente: notasCliente ?? this.notasCliente,
      estadoActual: estadoActual ?? this.estadoActual,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      costoEnvio: costoEnvio ?? this.costoEnvio,
      total: total ?? this.total,
      historialEstados: historialEstados ?? this.historialEstados,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

