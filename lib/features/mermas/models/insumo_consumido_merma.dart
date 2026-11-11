// lib/features/mermas/models/insumo_consumido_merma.dart
//
// Entidad de dominio que representa un insumo (materia prima o energético)
// consumido por las piezas que sufrieron merma (HU-06 – Criterio 3).
//
// Regla arquitectónica: Modelo de dominio puro sin dependencias visuales.

import '../../produccion/models/etapa_produccion.dart';

/// Representa un insumo invertido en una pieza antes de sufrir el daño.
class InsumoConsumidoMerma {
  const InsumoConsumidoMerma({
    required this.insumoId,
    required this.nombre,
    required this.unidad,
    required this.cantidadPorPieza,
    required this.costoPorUnidad,
    this.etapaAsociada = EtapaProduccion.barroCrudo,
  });

  /// Identificador del insumo o materia prima vinculada.
  final String insumoId;

  /// Nombre descriptivo del insumo (ej: "Barro negro y blanco", "Esmalte blanco").
  final String nombre;

  /// Unidad de medida ('kg' o 'lt').
  final String unidad;

  /// Cantidad de este insumo consumida por cada pieza individual.
  final double cantidadPorPieza;

  /// Costo económico por unidad de medida del insumo ($ MXN por kg o lt).
  final double costoPorUnidad;

  /// Etapa del oficio en la que se incorpora este insumo a la pieza.
  final EtapaProduccion etapaAsociada;

  // ── Cálculos de Dominio (HU-06 Criterio 3) ──────────────────────────────────

  /// Costo de este insumo invertido en una sola pieza ($ MXN).
  ///
  /// Fórmula: Cantidad por pieza × Costo por unidad de insumo.
  double get costoPorPieza => cantidadPorPieza * costoPorUnidad;

  /// Cantidad total de insumo desperdiciado para [piezasPerdidas] piezas.
  double cantidadTotalConsumida(int piezasPerdidas) {
    if (piezasPerdidas <= 0) return 0.0;
    return cantidadPorPieza * piezasPerdidas;
  }

  /// Costo total estimado de este insumo en las [piezasPerdidas] piezas dañadas ($ MXN).
  double subtotalParaPiezas(int piezasPerdidas) {
    if (piezasPerdidas <= 0) return 0.0;
    return costoPorPieza * piezasPerdidas;
  }

  // ── Plantilla Acumulativa por Etapa del Oficio ──────────────────────────────

  /// Genera los insumos estándar acumulados que una pieza ha consumido
  /// según la [etapa] en la que ocurrió el daño.
  ///
  /// En la talavera tradicional, una pieza rota en etapas avanzadas ya consumió
  /// los insumos de todas las etapas previas.
  static List<InsumoConsumidoMerma> plantillaPorEtapa(EtapaProduccion etapa) {
    final todosLosInsumosPorEtapa = <InsumoConsumidoMerma>[
      // Etapa 1: Barro crudo
      const InsumoConsumidoMerma(
        insumoId: 'ins_barro_pasta',
        nombre: 'Barro negro y blanco preparado',
        unidad: 'kg',
        cantidadPorPieza: 1.20,
        costoPorUnidad: 18.00, // $21.60 por pieza
        etapaAsociada: EtapaProduccion.barroCrudo,
      ),
      // Etapa 2: Jahuete (1ra quema)
      const InsumoConsumidoMerma(
        insumoId: 'ins_gas_jahuete',
        nombre: 'Gas LP (1ra quema de Jahuete)',
        unidad: 'lt',
        cantidadPorPieza: 0.80,
        costoPorUnidad: 15.00, // $12.00 por pieza
        etapaAsociada: EtapaProduccion.jahuete,
      ),
      // Etapa 3: Esmaltado
      const InsumoConsumidoMerma(
        insumoId: 'ins_esmalte_blanco',
        nombre: 'Esmalte blanco estannífero',
        unidad: 'lt',
        cantidadPorPieza: 0.25,
        costoPorUnidad: 60.00, // $15.00 por pieza
        etapaAsociada: EtapaProduccion.esmaltado,
      ),
      // Etapa 4: Decorado
      const InsumoConsumidoMerma(
        insumoId: 'ins_pigmentos_minerales',
        nombre: 'Pigmentos minerales (Azul cobalto y óxidos)',
        unidad: 'kg',
        cantidadPorPieza: 0.08,
        costoPorUnidad: 150.00, // $12.00 por pieza
        etapaAsociada: EtapaProduccion.decorado,
      ),
      // Etapa 5: Terminado (2da quema a 1050°C)
      const InsumoConsumidoMerma(
        insumoId: 'ins_gas_gran_fuego',
        nombre: 'Gas LP (2da quema Gran Fuego 1050°C)',
        unidad: 'lt',
        cantidadPorPieza: 1.00,
        costoPorUnidad: 15.00, // $15.00 por pieza
        etapaAsociada: EtapaProduccion.terminado,
      ),
    ];

    return todosLosInsumosPorEtapa
        .where((insumo) => insumo.etapaAsociada.orden <= etapa.orden)
        .toList();
  }

  // ── Serialización JSON ──────────────────────────────────────────────────────

  factory InsumoConsumidoMerma.fromJson(Map<String, dynamic> json) {
    return InsumoConsumidoMerma(
      insumoId: json['insumo_id'] as String? ?? 'ins_custom',
      nombre: json['nombre'] as String? ?? 'Insumo de producción',
      unidad: json['unidad'] as String? ?? 'kg',
      cantidadPorPieza: (json['cantidad_por_pieza'] as num?)?.toDouble() ?? 0.0,
      costoPorUnidad: (json['costo_por_unidad'] as num?)?.toDouble() ?? 0.0,
      etapaAsociada: EtapaProduccion.fromCodigo(json['etapa_asociada'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'insumo_id': insumoId,
      'nombre': nombre.trim(),
      'unidad': unidad,
      'cantidad_por_pieza': cantidadPorPieza,
      'costo_por_unidad': costoPorUnidad,
      'costo_por_pieza': costoPorPieza,
      'etapa_asociada': etapaAsociada.codigo,
    };
  }

  InsumoConsumidoMerma copyWith({
    String? insumoId,
    String? nombre,
    String? unidad,
    double? cantidadPorPieza,
    double? costoPorUnidad,
    EtapaProduccion? etapaAsociada,
  }) {
    return InsumoConsumidoMerma(
      insumoId: insumoId ?? this.insumoId,
      nombre: nombre ?? this.nombre,
      unidad: unidad ?? this.unidad,
      cantidadPorPieza: cantidadPorPieza ?? this.cantidadPorPieza,
      costoPorUnidad: costoPorUnidad ?? this.costoPorUnidad,
      etapaAsociada: etapaAsociada ?? this.etapaAsociada,
    );
  }
}

