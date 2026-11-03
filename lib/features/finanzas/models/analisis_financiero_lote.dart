// lib/features/finanzas/models/analisis_financiero_lote.dart
//
// Entidad de dominio que representa el análisis financiero completo de un lote
// de producción artesanal (HU-07).
//
// Cumple con:
//   - Criterio 1: Costo unitario = Gasto materia prima unitario + Merma prorrateada unitaria.
//   - Criterio 2: Desglose por categorías de gasto del lote.
//   - Criterio 3: Indicador de utilidad estimada (margen vs precio de venta).

import '../../produccion/models/etapa_produccion.dart';
import 'categoria_costo.dart';
import 'item_desglose_costo.dart';
import 'nivel_rentabilidad.dart';

/// Entidad inmutable de análisis financiero de un lote artesanal.
class AnalisisFinancieroLote {
  const AnalisisFinancieroLote({
    required this.id,
    required this.loteId,
    required this.loteCodigo,
    required this.cantidadPiezasIniciales,
    required this.piezasMermadas,
    required this.gastoMateriaPrimaTotal,
    required this.costoMermasTotal,
    required this.precioVentaUnitario,
    this.descripcion,
    this.etapaActual = EtapaProduccion.barroCrudo,
    this.desgloseCategorias = const [],
    this.fechaCreacion,
    this.updatedAt,
  });

  /// Identificador único del registro de costo.
  final String id;

  /// Identificador del lote de producción vinculado.
  final String loteId;

  /// Código o nombre del lote (ej: "LOTE-2024-001 (Vajilla Tradicional)").
  final String loteCodigo;

  /// Descripción o notas del tipo de pieza producida.
  final String? descripcion;

  /// Etapa actual en la que se encuentra el lote en el taller.
  final EtapaProduccion etapaActual;

  /// Cantidad total de piezas con las que inició la producción del lote.
  final int cantidadPiezasIniciales;

  /// Cantidad de piezas defectuosas o rotas en las distintas etapas (mermas).
  final int piezasMermadas;

  /// Inversión monetaria directa en materias primas consumidas para el lote (\$ MXN).
  final double gastoMateriaPrimaTotal;

  /// Costo económico total acumulado de las piezas mermadas (\$ MXN).
  final double costoMermasTotal;

  /// Precio de venta unitario fijado o sugerido al cliente (\$ MXN).
  final double precioVentaUnitario;

  /// Desglose estructurado de costos por categoría (HU-07 Criterio 2).
  final List<ItemDesgloseCosto> desgloseCategorias;

  /// Fecha de registro o creación del lote.
  final DateTime? fechaCreacion;

  /// Fecha de última actualización financiera.
  final DateTime? updatedAt;

  // ── Cálculos de Negocio Innegociables (HU-07) ───────────────────────────────

  /// Piezas útiles (sanas) que lograron sobrevivir al proceso artesanal.
  int get piezasUtiles {
    final utiles = cantidadPiezasIniciales - piezasMermadas;
    return utiles > 0 ? utiles : 0;
  }

  /// Denominador seguro para evitar divisiones entre cero si todas las piezas se mermaron.
  int get _divisorPiezasUtiles => piezasUtiles > 0 ? piezasUtiles : 1;

  /// Inversión total en la producción de este lote (materias primas + merma acumulada).
  double get costoTotalProduccion => gastoMateriaPrimaTotal + costoMermasTotal;

  // ── Criterio 1: Costo unitario con merma prorrateada ─────────────────────────

  /// Gasto de materia prima asignado a cada pieza útil terminada.
  double get gastoMateriaPrimaUnitario => gastoMateriaPrimaTotal / _divisorPiezasUtiles;

  /// Porción de la pérdida por merma que debe absorber cada pieza útil.
  double get mermaProrrateadaUnitaria => costoMermasTotal / _divisorPiezasUtiles;

  /// Costo unitario real por pieza: Materia Prima + Merma Prorrateada.
  ///
  /// Fórmula:
  /// Costo Unitario = (Gasto Materia Prima + Merma Total) / Piezas Útiles
  double get costoUnitario => gastoMateriaPrimaUnitario + mermaProrrateadaUnitaria;

  // ── Criterio 3: Utilidad estimada, margen comercial y rentabilidad ──────────

  /// Utilidad o ganancia bruta estimada por cada pieza vendida ($ MXN).
  ///
  /// Fórmula: Precio de Venta - Costo Unitario
  double get utilidadUnitaria => precioVentaUnitario - costoUnitario;

  /// Margen de utilidad porcentual sobre el precio de venta (0% a 100%).
  ///
  /// Fórmula: (Utilidad Unitaria / Precio de Venta) * 100
  double get margenUtilidadPorcentaje {
    if (precioVentaUnitario <= 0.0) return 0.0;
    return (utilidadUnitaria / precioVentaUnitario) * 100.0;
  }

  /// Markup (porcentaje de ganancia sobre el costo).
  ///
  /// Fórmula: (Utilidad Unitaria / Costo Unitario) * 100
  double get markupPorcentaje {
    if (costoUnitario <= 0.0) return 0.0;
    return (utilidadUnitaria / costoUnitario) * 100.0;
  }

  /// Utilidad total estimada que ingresará al taller si se venden todas las piezas útiles.
  double get utilidadTotalEstimada => utilidadUnitaria * piezasUtiles;

  /// Ingreso total bruto estimado por la venta del lote de piezas útiles.
  double get ingresoTotalEstimado => precioVentaUnitario * piezasUtiles;

  /// Nivel de rentabilidad calificado (Excelente, Saludable, Ajustado, En Pérdida).
  NivelRentabilidad get nivelRentabilidad => NivelRentabilidad.evaluar(margenUtilidadPorcentaje);

  /// Porcentaje de piezas perdidas por merma respecto al lote inicial.
  double get porcentajePiezasMermadas {
    if (cantidadPiezasIniciales <= 0) return 0.0;
    return (piezasMermadas / cantidadPiezasIniciales) * 100.0;
  }

  /// Indica si el lote presenta mermas registradas.
  bool get tieneMermas => piezasMermadas > 0;

  // ── Criterio 2: Desglose por Categoría Completo ──────────────────────────────

  /// Retorna la lista de desglose por categoría asegurando que incluya
  /// la partida de merma prorrateada y los porcentajes calculados sobre el costo total.
  List<ItemDesgloseCosto> get desgloseCompleto {
    if (desgloseCategorias.isNotEmpty) {
      final total = costoTotalProduccion;
      return desgloseCategorias.map((item) => item.conPorcentajeRecalculado(total)).toList();
    }

    // Si no viene desglosado expresamente, generamos las proporciones representativas
    // de la talavera tradicional de Dolores Hidalgo:
    // - Barro y Pastas: 35% del gasto de materias primas
    // - Esmaltes y Vidriado: 25%
    // - Pigmentos y Decorado: 20%
    // - Horneado y Combustible: 20%
    // - Merma Prorrateada: Monto exacto de costoMermasTotal
    final mp = gastoMateriaPrimaTotal;
    final total = costoTotalProduccion > 0 ? costoTotalProduccion : 1.0;

    final items = <ItemDesgloseCosto>[
      ItemDesgloseCosto(
        categoria: CategoriaCosto.barroPastas,
        monto: mp * 0.35,
        porcentaje: ((mp * 0.35) / total) * 100.0,
      ),
      ItemDesgloseCosto(
        categoria: CategoriaCosto.esmaltesVidriado,
        monto: mp * 0.25,
        porcentaje: ((mp * 0.25) / total) * 100.0,
      ),
      ItemDesgloseCosto(
        categoria: CategoriaCosto.pigmentosDecorado,
        monto: mp * 0.20,
        porcentaje: ((mp * 0.20) / total) * 100.0,
      ),
      ItemDesgloseCosto(
        categoria: CategoriaCosto.horneadoEnergia,
        monto: mp * 0.20,
        porcentaje: ((mp * 0.20) / total) * 100.0,
      ),
    ];

    if (costoMermasTotal > 0.0) {
      items.add(
        ItemDesgloseCosto(
          categoria: CategoriaCosto.mermaProrrateada,
          monto: costoMermasTotal,
          porcentaje: (costoMermasTotal / total) * 100.0,
        ),
      );
    }

    return items;
  }

  // ── Serialización ──────────────────────────────────────────────────────────

  factory AnalisisFinancieroLote.fromJson(Map<String, dynamic> json) {
    List<ItemDesgloseCosto> categorias = [];
    if (json['desglose_categorias'] != null && json['desglose_categorias'] is List) {
      categorias = (json['desglose_categorias'] as List)
          .map((item) => ItemDesgloseCosto.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return AnalisisFinancieroLote(
      id: json['id'] as String? ?? '',
      loteId: json['lote_id'] as String? ?? '',
      loteCodigo: json['lote_codigo'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      etapaActual: EtapaProduccion.fromCodigo(json['etapa_actual'] as String?),
      cantidadPiezasIniciales: (json['cantidad_piezas_iniciales'] as num?)?.toInt() ?? 0,
      piezasMermadas: (json['piezas_mermadas'] as num?)?.toInt() ?? 0,
      gastoMateriaPrimaTotal: (json['gasto_materia_prima_total'] as num?)?.toDouble() ?? 0.0,
      costoMermasTotal: (json['costo_mermas_total'] as num?)?.toDouble() ?? 0.0,
      precioVentaUnitario: (json['precio_venta_unitario'] as num?)?.toDouble() ?? 0.0,
      desgloseCategorias: categorias,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.tryParse(json['fecha_creacion'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'lote_id': loteId,
      'lote_codigo': loteCodigo,
      'descripcion': descripcion,
      'etapa_actual': etapaActual.codigo,
      'cantidad_piezas_iniciales': cantidadPiezasIniciales,
      'piezas_mermadas': piezasMermadas,
      'gasto_materia_prima_total': gastoMateriaPrimaTotal,
      'costo_mermas_total': costoMermasTotal,
      'precio_venta_unitario': precioVentaUnitario,
      'costo_unitario': costoUnitario,
      'margen_utilidad_porcentaje': margenUtilidadPorcentaje,
      'desglose_categorias': desgloseCompleto.map((c) => c.toJson()).toList(),
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  AnalisisFinancieroLote copyWith({
    String? id,
    String? loteId,
    String? loteCodigo,
    String? descripcion,
    EtapaProduccion? etapaActual,
    int? cantidadPiezasIniciales,
    int? piezasMermadas,
    double? gastoMateriaPrimaTotal,
    double? costoMermasTotal,
    double? precioVentaUnitario,
    List<ItemDesgloseCosto>? desgloseCategorias,
    DateTime? fechaCreacion,
    DateTime? updatedAt,
  }) {
    return AnalisisFinancieroLote(
      id: id ?? this.id,
      loteId: loteId ?? this.loteId,
      loteCodigo: loteCodigo ?? this.loteCodigo,
      descripcion: descripcion ?? this.descripcion,
      etapaActual: etapaActual ?? this.etapaActual,
      cantidadPiezasIniciales: cantidadPiezasIniciales ?? this.cantidadPiezasIniciales,
      piezasMermadas: piezasMermadas ?? this.piezasMermadas,
      gastoMateriaPrimaTotal: gastoMateriaPrimaTotal ?? this.gastoMateriaPrimaTotal,
      costoMermasTotal: costoMermasTotal ?? this.costoMermasTotal,
      precioVentaUnitario: precioVentaUnitario ?? this.precioVentaUnitario,
      desgloseCategorias: desgloseCategorias ?? this.desgloseCategorias,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

