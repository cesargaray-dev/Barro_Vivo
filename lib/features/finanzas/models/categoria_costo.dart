// lib/features/finanzas/models/categoria_costo.dart
//
// Enumerador de dominio para las categorías de costo en la producción
// artesanal de talavera (HU-07).
//
// Regla arquitectónica: Modelo de dominio puro sin dependencias visuales.

/// Categorías típicas de costo en el oficio de la talavera.
enum CategoriaCosto {
  barroPastas('barro_pastas', 'Barro y Pastas', 'Arcilla roja, barro blanco y preparación de pasta'),
  esmaltesVidriado('esmaltes_vidriado', 'Esmaltes y Vidriado', 'Frita vítrea, óxido de estaño y base blanca'),
  pigmentosDecorado('pigmentos_decorado', 'Pigmentos y Decorado', 'Cobalto azul, antimonio, óxido ferroso'),
  mermaProrrateada('merma_prorrateada', 'Merma Prorrateada', 'Pérdidas acumuladas en secado, horno y decorado'),
  horneadoEnergia('horneado_energia', 'Horneado y Combustible', 'Gas LP para primera y segunda quema'),
  otrosInsumos('otros_insumos', 'Otros Insumos del Taller', 'Herramientas, pinceles, lijas y auxiliares');

  const CategoriaCosto(this.codigo, this.nombre, this.descripcion);

  final String codigo;
  final String nombre;
  final String descripcion;

  /// Obtiene la categoría a partir de su código persistido.
  static CategoriaCosto fromCodigo(String? codigo) {
    if (codigo == null) return CategoriaCosto.otrosInsumos;
    return CategoriaCosto.values.firstWhere(
      (c) => c.codigo.toLowerCase() == codigo.toLowerCase(),
      orElse: () => CategoriaCosto.otrosInsumos,
    );
  }
}

