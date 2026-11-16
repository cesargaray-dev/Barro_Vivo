// lib/features/pedidos/models/item_pedido.dart
//
// Partida incluida dentro de un pedido confirmado (HU-09).

/// Detalle inmutable de un producto dentro de una orden confirmada.
class ItemPedido {
  const ItemPedido({
    required this.piezaId,
    required this.loteCodigo,
    required this.nombrePieza,
    required this.cantidad,
    required this.precioUnitario,
  });

  final String piezaId;
  final String loteCodigo;
  final String nombrePieza;
  final int cantidad;
  final double precioUnitario;

  /// Importe total de la línea ($ MXN).
  double get subtotal => cantidad * precioUnitario;

  factory ItemPedido.fromJson(Map<String, dynamic> json) {
    return ItemPedido(
      piezaId: json['pieza_id'] as String? ?? '',
      loteCodigo: json['lote_codigo'] as String? ?? '',
      nombrePieza: json['nombre_pieza'] as String? ?? '',
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 0,
      precioUnitario: (json['precio_unitario'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'pieza_id': piezaId,
        'lote_codigo': loteCodigo,
        'nombre_pieza': nombrePieza,
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
        'subtotal': subtotal,
      };
}

