// lib/features/catalogo/models/item_carrito.dart
//
// Representa una línea dentro del carrito de compras del cliente (HU-08).

import 'pieza_catalogo.dart';

/// Partida inmutable dentro del carrito de compras.
class ItemCarrito {
  const ItemCarrito({
    required this.pieza,
    required this.cantidad,
  });

  /// Pieza seleccionada del catálogo.
  final PiezaCatalogo pieza;

  /// Cantidad solicitada por el cliente.
  final int cantidad;

  /// Precio unitario al momento de agregar al carrito ($ MXN).
  double get precioUnitario => pieza.precioUnitario;

  /// Subtotal explícito de esta partida ($ MXN).
  double get subtotal => pieza.precioUnitario * cantidad;

  /// Indica si aún se pueden agregar más unidades sin exceder la existencia.
  bool get puedeIncrementar => cantidad < pieza.existencia;

  /// Existencia máxima disponible en taller para esta pieza.
  int get stockDisponible => pieza.existencia;

  ItemCarrito copyWith({
    PiezaCatalogo? pieza,
    int? cantidad,
  }) {
    return ItemCarrito(
      pieza: pieza ?? this.pieza,
      cantidad: cantidad ?? this.cantidad,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemCarrito &&
        other.pieza == pieza &&
        other.cantidad == cantidad;
  }

  @override
  int get hashCode => Object.hash(pieza, cantidad);
}

