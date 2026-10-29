// lib/features/produccion/models/lote_produccion.dart
//
// Entidad de dominio que representa un Lote de Producción en el taller – HU-05.
//
// Reglas de negocio:
//   1. Todo lote nuevo inicia en la etapa [EtapaProduccion.barroCrudo].
//   2. El lote solo puede avanzar a la etapa inmediata siguiente de las 5 estrictas.
//   3. Conserva su lista histórica de transiciones de etapa con sus fechas.

import 'etapa_produccion.dart';
import 'historial_etapa.dart';

/// Excepción de dominio cuando se intenta mover un lote a una etapa no permitida.
class TransicionEtapaInvalidaException implements Exception {
  const TransicionEtapaInvalidaException({
    required this.etapaActual,
    required this.etapaIntentada,
    this.loteCodigo,
  });

  final EtapaProduccion etapaActual;
  final EtapaProduccion etapaIntentada;
  final String? loteCodigo;

  @override
  String toString() {
    final codigoStr = loteCodigo != null ? ' en el lote "$loteCodigo"' : '';
    if (etapaActual.esUltima) {
      return 'El lote$codigoStr ya se encuentra en la etapa final ("${etapaActual.titulo}") y no puede avanzar más.';
    }
    return 'Transición inválida$codigoStr: no se puede pasar de "${etapaActual.titulo}" a "${etapaIntentada.titulo}". '
        'La siguiente etapa estricta debe ser "${etapaActual.siguiente?.titulo}".';
  }
}

/// Entidad inmutable que representa un Lote de Producción en el taller.
class LoteProduccion {
  const LoteProduccion({
    required this.id,
    required this.codigo,
    required this.cantidadPiezas,
    required this.fechaCreacion,
    this.descripcion,
    this.etapaActual = EtapaProduccion.barroCrudo,
    this.historial = const [],
    this.activo = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Identificador único (UUID de Supabase).
  final String id;

  /// Código o nombre de identificación del lote (ej: "LOTE-2024-001" o "Vajilla Azul").
  final String codigo;

  /// Cantidad de piezas elaboradas en este lote.
  final int cantidadPiezas;

  /// Fecha asignada de inicio/creación del lote (Criterio 1).
  final DateTime fechaCreacion;

  /// Descripción o notas del tipo de piezas en producción.
  final String? descripcion;

  /// Etapa actual del oficio (Criterio 2).
  final EtapaProduccion etapaActual;

  /// Historial ordenado de transiciones de etapas con fechas (Criterio 3).
  final List<HistorialEtapa> historial;

  /// Borrado lógico (true = activo en taller).
  final bool activo;

  /// Timestamp de creación en base de datos.
  final DateTime? createdAt;

  /// Timestamp de última actualización.
  final DateTime? updatedAt;

  // ── Getters de Negocio ──────────────────────────────────────────────────────

  /// Determina si el lote puede avanzar a una siguiente etapa.
  bool get puedeAvanzar => etapaActual.siguiente != null;

  /// La siguiente etapa estricta a la que puede avanzar el lote, o null si está terminado.
  EtapaProduccion? get siguienteEtapa => etapaActual.siguiente;

  /// Indica si el lote ha completado las 5 etapas del oficio.
  bool get estaTerminado => etapaActual.esUltima;

  /// Progreso en porcentaje normalizado de 0.2 (20%) a 1.0 (100%).
  double get progresoPorcentaje => etapaActual.orden / 5.0;

  /// Porcentaje de progreso expresado como número entero (20 a 100).
  int get progresoEntero => (progresoPorcentaje * 100).round();

  /// Busca en el historial la fecha en que se registró una etapa específica.
  DateTime? fechaDeEtapa(EtapaProduccion etapa) {
    try {
      final entry = historial.firstWhere((h) => h.etapa == etapa);
      return entry.fecha;
    } catch (_) {
      return null;
    }
  }

  /// Retorna una nueva copia del lote habiendo avanzado a la [siguienteEtapa].
  ///
  /// Lanza [TransicionEtapaInvalidaException] si la transición no cumple
  /// con la secuencia estricta:
  /// barro crudo -> jahuete -> esmaltado -> decorado -> terminado.
  LoteProduccion avanzarASiguienteEtapa({
    required DateTime fecha,
    String? notas,
    String? historialId,
  }) {
    final proxima = siguienteEtapa;
    if (proxima == null) {
      throw TransicionEtapaInvalidaException(
        etapaActual: etapaActual,
        etapaIntentada: etapaActual,
        loteCodigo: codigo,
      );
    }

    final nuevoRegistro = HistorialEtapa(
      id: historialId ?? 'hist_${DateTime.now().microsecondsSinceEpoch}',
      loteId: id,
      etapa: proxima,
      fecha: fecha,
      notas: notas,
      createdAt: DateTime.now(),
    );

    return copyWith(
      etapaActual: proxima,
      historial: [...historial, nuevoRegistro],
      updatedAt: DateTime.now(),
    );
  }

  /// Fábrica desde JSON de Supabase.
  factory LoteProduccion.fromJson(Map<String, dynamic> json, {List<HistorialEtapa>? historial}) {
    List<HistorialEtapa> listaHistorial = historial ?? [];

    // Si viene la relación incrustada desde Supabase (ej: lotes_historial_etapas)
    if (json['lotes_historial_etapas'] != null && json['lotes_historial_etapas'] is List) {
      listaHistorial = (json['lotes_historial_etapas'] as List)
          .map((h) => HistorialEtapa.fromJson(h as Map<String, dynamic>))
          .toList();
    } else if (json['historial'] != null && json['historial'] is List) {
      listaHistorial = (json['historial'] as List)
          .map((h) => HistorialEtapa.fromJson(h as Map<String, dynamic>))
          .toList();
    }

    // Ordenar historial cronológicamente
    listaHistorial.sort((a, b) => a.fecha.compareTo(b.fecha));

    return LoteProduccion(
      id: json['id'] as String? ?? '',
      codigo: json['codigo'] as String? ?? '',
      cantidadPiezas: (json['cantidad_piezas'] as num?)?.toInt() ?? 0,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.tryParse(json['fecha_creacion'].toString()) ?? DateTime.now()
          : DateTime.now(),
      descripcion: json['descripcion'] as String?,
      etapaActual: EtapaProduccion.fromCodigo(json['etapa_actual'] as String?),
      historial: listaHistorial,
      activo: json['activo'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  /// Serializa el lote para inserción o actualización en Supabase.
  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'codigo': codigo.trim(),
      'cantidad_piezas': cantidadPiezas,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'descripcion': descripcion?.trim(),
      'etapa_actual': etapaActual.codigo,
      'activo': activo,
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  LoteProduccion copyWith({
    String? id,
    String? codigo,
    int? cantidadPiezas,
    DateTime? fechaCreacion,
    String? descripcion,
    EtapaProduccion? etapaActual,
    List<HistorialEtapa>? historial,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoteProduccion(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      cantidadPiezas: cantidadPiezas ?? this.cantidadPiezas,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      descripcion: descripcion ?? this.descripcion,
      etapaActual: etapaActual ?? this.etapaActual,
      historial: historial ?? this.historial,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
