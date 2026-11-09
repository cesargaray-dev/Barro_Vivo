// lib/features/mermas/models/registro_merma.dart
//
// Entidad de dominio que representa un Registro de Merma de un lote con su
// evidencia fotográfica obligatoria y cálculo de costo estimado según los
// insumos consumidos (HU-06).
//
// Criterios de Aceptación:
//   1. Se pueden registrar piezas perdidas indicando la etapa en la que ocurrió
//      el daño y el motivo (despostillado, rotura, etc.).
//   2. Es obligatorio poder adjuntar una evidencia fotográfica del daño al
//      registrar la merma.
//   3. El sistema calcula el costo estimado de la pérdida según los insumos
//      consumidos.
//
// Regla arquitectónica: Modelo de dominio puro sin dependencias visuales.

import '../../produccion/models/etapa_produccion.dart';
import 'insumo_consumido_merma.dart';
import 'motivo_merma.dart';

// ── Excepciones de Dominio (HU-06) ────────────────────────────────────────────

/// Excepción lanzada cuando se intenta registrar una merma sin evidencia fotográfica (Criterio 2).
class EvidenciaFotograficaRequeridaException implements Exception {
  const EvidenciaFotograficaRequeridaException([
    this.message = 'Es obligatorio adjuntar una evidencia fotográfica del daño para registrar la merma.',
  ]);

  final String message;

  @override
  String toString() => message;
}

/// Excepción lanzada cuando la cantidad de piezas perdidas es inválida (Criterio 1).
class CantidadMermaInvalidaException implements Exception {
  const CantidadMermaInvalidaException([
    this.message = 'La cantidad de piezas perdidas debe ser mayor a cero.',
  ]);

  final String message;

  @override
  String toString() => message;
}

/// Excepción lanzada cuando no se especifican insumos consumidos válidos (Criterio 3).
class InsumosMermaVaciosException implements Exception {
  const InsumosMermaVaciosException([
    this.message = 'Debe incluir al menos un insumo consumido con costo mayor a cero para estimar la pérdida.',
  ]);

  final String message;

  @override
  String toString() => message;
}

// ── Entidad Principal: RegistroMerma ──────────────────────────────────────────

/// Entidad inmutable que representa el registro de piezas perdidas (merma) en un lote.
class RegistroMerma {
  const RegistroMerma({
    required this.id,
    required this.loteId,
    required this.loteCodigo,
    required this.etapa,
    required this.motivo,
    required this.cantidadPiezas,
    required this.evidenciaUrl,
    required this.insumosConsumidos,
    required this.fecha,
    this.evidenciaDescripcion,
    this.observaciones,
    this.activo = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Identificador único del registro de merma (UUID).
  final String id;

  /// Identificador del lote de producción afectado.
  final String loteId;

  /// Código o nombre legible del lote afectado (ej: "LOTE-2024-001").
  final String loteCodigo;

  /// Etapa del oficio en la que ocurrió el daño (Criterio 1).
  final EtapaProduccion etapa;

  /// Motivo del daño: despostillado, rotura, grieta térmica, etc. (Criterio 1).
  final MotivoMerma motivo;

  /// Cantidad de piezas perdidas en este incidente (Criterio 1).
  final int cantidadPiezas;

  /// Ruta, URI o identificador del archivo de evidencia fotográfica del daño (Criterio 2 – Obligatorio).
  final String evidenciaUrl;

  /// Nota o pie de foto descriptivo de la evidencia adjunta.
  final String? evidenciaDescripcion;

  /// Lista detallada de insumos consumidos por las piezas mermadas hasta la [etapa] (Criterio 3).
  final List<InsumoConsumidoMerma> insumosConsumidos;

  /// Observaciones adicionales del artesano sobre el incidente.
  final String? observaciones;

  /// Fecha y hora en que se registró u ocurrió la merma.
  final DateTime fecha;

  /// Indicador de registro activo (borrado lógico).
  final bool activo;

  /// Timestamp de creación en base de datos.
  final DateTime? createdAt;

  /// Timestamp de última modificación.
  final DateTime? updatedAt;

  // ── Reglas y Cálculos de Negocio (HU-06) ────────────────────────────────────

  /// Verifica que la merma cuente con una evidencia fotográfica válida adjunta (Criterio 2).
  bool get tieneEvidenciaFotografica => evidenciaUrl.trim().isNotEmpty;

  /// Costo unitario estimado por cada pieza dañada según la suma de insumos consumidos (Criterio 3).
  ///
  /// Fórmula: ∑ (cantidadPorPieza × costoPorUnidad) de cada insumo consumido.
  double get costoUnitarioEstimado => calcularCostoUnitario(insumosConsumidos);

  /// Costo total estimado de la pérdida para todas las piezas mermadas en este registro (Criterio 3).
  ///
  /// Fórmula: Costo Unitario Estimado × Cantidad de Piezas Perdidas.
  double get costoTotalEstimado => calcularCostoTotal(
        cantidadPiezas: cantidadPiezas,
        insumos: insumosConsumidos,
      );

  /// Calcula el costo unitario por pieza a partir de una lista de [insumos] consumidos.
  static double calcularCostoUnitario(List<InsumoConsumidoMerma> insumos) {
    return insumos.fold<double>(0.0, (acumulado, item) => acumulado + item.costoPorPieza);
  }

  /// Calcula el costo total estimado de la pérdida según [cantidadPiezas] y los [insumos] consumidos.
  static double calcularCostoTotal({
    required int cantidadPiezas,
    required List<InsumoConsumidoMerma> insumos,
  }) {
    if (cantidadPiezas <= 0) return 0.0;
    return calcularCostoUnitario(insumos) * cantidadPiezas;
  }

  /// Valida las invariantes de negocio de HU-06.
  ///
  /// Lanza:
  /// - [CantidadMermaInvalidaException] si [cantidadPiezas] <= 0.
  /// - [EvidenciaFotograficaRequeridaException] si [evidenciaUrl] está vacía.
  /// - [InsumosMermaVaciosException] si no hay insumos consumidos o el costo es <= 0.
  void validarReglasDeNegocio() {
    if (cantidadPiezas <= 0) {
      throw const CantidadMermaInvalidaException();
    }
    if (!tieneEvidenciaFotografica) {
      throw const EvidenciaFotograficaRequeridaException();
    }
    if (insumosConsumidos.isEmpty || costoUnitarioEstimado <= 0.0) {
      throw const InsumosMermaVaciosException();
    }
  }

  // ── Serialización JSON (Supabase) ───────────────────────────────────────────

  factory RegistroMerma.fromJson(Map<String, dynamic> json) {
    final etapa = EtapaProduccion.fromCodigo(json['etapa'] as String?);

    List<InsumoConsumidoMerma> listaInsumos = [];
    if (json['insumos_consumidos'] != null && json['insumos_consumidos'] is List) {
      listaInsumos = (json['insumos_consumidos'] as List)
          .map((item) => InsumoConsumidoMerma.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // Si el registro viene de BD sin desglose explícito pero con costo_unitario_estimado,
    // reconstruimos o usamos la plantilla de la etapa.
    if (listaInsumos.isEmpty) {
      final costoUnitarioJson = (json['costo_unitario_estimado'] as num?)?.toDouble() ?? 0.0;
      if (costoUnitarioJson > 0.0) {
        listaInsumos = [
          InsumoConsumidoMerma(
            insumoId: 'ins_consolidado',
            nombre: 'Insumos acumulados hasta ${etapa.titulo}',
            unidad: 'lote',
            cantidadPorPieza: 1.0,
            costoPorUnidad: costoUnitarioJson,
            etapaAsociada: etapa,
          ),
        ];
      } else {
        listaInsumos = InsumoConsumidoMerma.plantillaPorEtapa(etapa);
      }
    }

    return RegistroMerma(
      id: json['id'] as String? ?? '',
      loteId: json['lote_id'] as String? ?? '',
      loteCodigo: json['lote_codigo'] as String? ?? '',
      etapa: etapa,
      motivo: MotivoMerma.fromCodigo(json['motivo'] as String?),
      cantidadPiezas: (json['cantidad_piezas'] as num?)?.toInt() ?? 1,
      evidenciaUrl: json['evidencia_url'] as String? ?? '',
      evidenciaDescripcion: json['evidencia_descripcion'] as String?,
      insumosConsumidos: listaInsumos,
      observaciones: json['observaciones'] as String?,
      fecha: json['fecha'] != null
          ? DateTime.tryParse(json['fecha'].toString()) ?? DateTime.now()
          : DateTime.now(),
      activo: json['activo'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'lote_id': loteId,
      'lote_codigo': loteCodigo.trim(),
      'etapa': etapa.codigo,
      'motivo': motivo.codigo,
      'cantidad_piezas': cantidadPiezas,
      'evidencia_url': evidenciaUrl.trim(),
      'evidencia_descripcion': evidenciaDescripcion?.trim(),
      'insumos_consumidos': insumosConsumidos.map((i) => i.toJson()).toList(),
      'costo_unitario_estimado': costoUnitarioEstimado,
      'costo_total_estimado': costoTotalEstimado,
      'observaciones': observaciones?.trim(),
      'fecha': fecha.toIso8601String(),
      'activo': activo,
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  RegistroMerma copyWith({
    String? id,
    String? loteId,
    String? loteCodigo,
    EtapaProduccion? etapa,
    MotivoMerma? motivo,
    int? cantidadPiezas,
    String? evidenciaUrl,
    String? evidenciaDescripcion,
    List<InsumoConsumidoMerma>? insumosConsumidos,
    String? observaciones,
    DateTime? fecha,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RegistroMerma(
      id: id ?? this.id,
      loteId: loteId ?? this.loteId,
      loteCodigo: loteCodigo ?? this.loteCodigo,
      etapa: etapa ?? this.etapa,
      motivo: motivo ?? this.motivo,
      cantidadPiezas: cantidadPiezas ?? this.cantidadPiezas,
      evidenciaUrl: evidenciaUrl ?? this.evidenciaUrl,
      evidenciaDescripcion: evidenciaDescripcion ?? this.evidenciaDescripcion,
      insumosConsumidos: insumosConsumidos ?? this.insumosConsumidos,
      observaciones: observaciones ?? this.observaciones,
      fecha: fecha ?? this.fecha,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

