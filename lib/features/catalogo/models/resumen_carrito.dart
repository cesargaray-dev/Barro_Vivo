// lib/features/catalogo/models/resumen_carrito.dart
//
// Modelo de resumen financiero del carrito con totales explícitos antes de
// proceder al pago (HU-08 Criterio 2).

import 'item_carrito.dart';

/// Totales calculados y explícitos del carrito del cliente.
class ResumenCarrito {
  const ResumenCarrito({
    required this.items,
  });

  /// Monto mínimo en piezas para obtener embalaje y envío sin costo ($ MXN).
  static const double umbralEnvioGratis = 1500.0;

  /// Costo estándar de embalaje artesanal y envío asegurado ($ MXN).
  static const double costoEnvioEstandar = 150.0;

  /// Partidas actuales en el carrito.
  final List<ItemCarrito> items;

  /// Indica si el carrito no contiene artículos.
  bool get estaVacio => items.isEmpty;

  /// Número de productos distintos en el carrito.
  int get totalPartidas => items.length;

  /// Suma total de piezas físicas solicitadas.
  int get totalPiezas => items.fold<int>(0, (acc, i) => acc + i.cantidad);

  /// Suma de los subtotales de cada partida antes de envío ($ MXN).
  double get subtotalProductos =>
      items.fold<double>(0.0, (acc, i) => acc + i.subtotal);

  /// Costo de embalaje y envío aplicable según el subtotal.
  double get costoEnvio {
    if (estaVacio) return 0.0;
    return subtotalProductos >= umbralEnvioGratis ? 0.0 : costoEnvioEstandar;
  }

  /// Total final explícito a pagar por el cliente ($ MXN).
  double get totalAPagar => subtotalProductos + costoEnvio;

  /// Indica si la orden califica para envío gratuito.
  bool get tieneEnvioGratis => !estaVacio && costoEnvio == 0.0;

  /// Monto restante necesario para alcanzar envío gratuito ($ MXN).
  double get faltanteParaEnvioGratis {
    if (subtotalProductos >= umbralEnvioGratis) return 0.0;
    return umbralEnvioGratis - subtotalProductos;
  }
}

