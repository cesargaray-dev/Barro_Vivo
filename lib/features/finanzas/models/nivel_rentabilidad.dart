// lib/features/finanzas/models/nivel_rentabilidad.dart
//
// Clasificación de rentabilidad y salud financiera de un lote o producto (HU-07).
//
// Regla arquitectónica: Modelo de dominio puro sin dependencias visuales.

/// Nivel de rentabilidad según el margen porcentual de utilidad sobre el precio de venta.
enum NivelRentabilidad {
  excelente('Excelente', 'Margen óptimo (>= 45%), taller altamente rentable'),
  saludable('Saludable', 'Margen adecuado (25% a 44%), cubre costos y genera ganancia sólida'),
  ajustado('Ajustado', 'Margen estrecho (1% a 24%), vulnerable a fluctuaciones de insumos'),
  perdida('En Pérdida', 'Precio por debajo del costo unitario (<= 0%), el taller pierde dinero');

  const NivelRentabilidad(this.etiqueta, this.descripcion);

  final String etiqueta;
  final String descripcion;

  /// Evalúa el nivel de rentabilidad a partir del [margenPorcentaje] (0 a 100 o negativo).
  static NivelRentabilidad evaluar(double margenPorcentaje) {
    if (margenPorcentaje >= 45.0) {
      return NivelRentabilidad.excelente;
    } else if (margenPorcentaje >= 25.0) {
      return NivelRentabilidad.saludable;
    } else if (margenPorcentaje > 0.0) {
      return NivelRentabilidad.ajustado;
    } else {
      return NivelRentabilidad.perdida;
    }
  }

  /// Indica si el margen representa una situación financiera de alerta o peligro.
  bool get esCritico => this == NivelRentabilidad.perdida || this == NivelRentabilidad.ajustado;

  /// Indica si el margen es rentable y seguro para el taller.
  bool get esRentable => this == NivelRentabilidad.excelente || this == NivelRentabilidad.saludable;
}

