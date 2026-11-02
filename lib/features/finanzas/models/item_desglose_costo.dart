// lib/features/finanzas/models/item_desglose_costo.dart
//
// Representación inmutable de una partida o categoría de costo (HU-07).
//
// Regla arquitectónica: Modelo de dominio puro sin dependencias visuales.

import 'categoria_costo.dart';

/// Partida de costo categorizada con su monto y porcentaje de participación.
class ItemDesgloseCosto {
  const ItemDesgloseCosto({
    required this.categoria,
    required this.monto,
    this.porcentaje = 0.0,
  });

  /// Categoría del costo (materia prima, merma prorrateada, etc.).
  final CategoriaCosto categoria;

  /// Monto total acumulado en pesos mexicanos (\$ MXN).
  final double monto;

  /// Porcentaje sobre el costo total (0.0 a 100.0).
  final double porcentaje;

  /// Retorna una copia con el porcentaje recalculado con base en el [costoTotal].
  ItemDesgloseCosto conPorcentajeRecalculado(double costoTotal) {
    final nuevoPorcentaje = costoTotal > 0.0 ? (monto / costoTotal) * 100.0 : 0.0;
    return copyWith(porcentaje: nuevoPorcentaje);
  }

  factory ItemDesgloseCosto.fromJson(Map<String, dynamic> json) {
    return ItemDesgloseCosto(
      categoria: CategoriaCosto.fromCodigo(json['categoria'] as String?),
      monto: (json['monto'] as num?)?.toDouble() ?? 0.0,
      porcentaje: (json['porcentaje'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoria': categoria.codigo,
      'monto': monto,
      'porcentaje': porcentaje,
    };
  }

  ItemDesgloseCosto copyWith({
    CategoriaCosto? categoria,
    double? monto,
    double? porcentaje,
  }) {
    return ItemDesgloseCosto(
      categoria: categoria ?? this.categoria,
      monto: monto ?? this.monto,
      porcentaje: porcentaje ?? this.porcentaje,
    );
  }
}

