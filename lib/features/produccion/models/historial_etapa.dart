// lib/features/produccion/models/historial_etapa.dart
//
// Modelo inmutable que registra cada avance de etapa de un lote – HU-05.
// Cumple con el criterio: "Se mantiene un historial consultable de las fechas
// en las que el lote avanzó de etapa."

import 'etapa_produccion.dart';

/// Registro histórico inmutable de la transición de un lote a una etapa.
class HistorialEtapa {
  const HistorialEtapa({
    required this.id,
    required this.loteId,
    required this.etapa,
    required this.fecha,
    this.notas,
    this.createdAt,
  });

  /// Identificador único del registro de historial (UUID).
  final String id;

  /// Identificador del lote al que pertenece este evento.
  final String loteId;

  /// Etapa alcanzada por el lote.
  final EtapaProduccion etapa;

  /// Fecha en la que ocurrió el avance de etapa (asignada por el artesano o sistema).
  final DateTime fecha;

  /// Observaciones opcionales del artesano (ej: 'Curva de temperatura completada').
  final String? notas;

  /// Timestamp de auditoría de creación en la base de datos.
  final DateTime? createdAt;

  /// Crea una instancia a partir del mapa JSON devuelto por Supabase.
  factory HistorialEtapa.fromJson(Map<String, dynamic> json) {
    return HistorialEtapa(
      id: json['id'] as String? ?? '',
      loteId: json['lote_id'] as String? ?? '',
      etapa: EtapaProduccion.fromCodigo(json['etapa'] as String?),
      fecha: json['fecha'] != null
          ? DateTime.tryParse(json['fecha'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notas: json['notas'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// Serializa el registro para inserción en Supabase.
  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'lote_id': loteId,
      'etapa': etapa.codigo,
      'fecha': fecha.toIso8601String(),
      'notas': notas?.trim(),
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  HistorialEtapa copyWith({
    String? id,
    String? loteId,
    EtapaProduccion? etapa,
    DateTime? fecha,
    String? notas,
    DateTime? createdAt,
  }) {
    return HistorialEtapa(
      id: id ?? this.id,
      loteId: loteId ?? this.loteId,
      etapa: etapa ?? this.etapa,
      fecha: fecha ?? this.fecha,
      notas: notas ?? this.notas,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
