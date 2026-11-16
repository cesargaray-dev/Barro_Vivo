// lib/features/catalogo/models/pieza_catalogo.dart
//
// Entidad de dominio que representa una pieza artesanal disponible o en taller (HU-08).
//
// Regla de negocio crítica:
//   El catálogo publicado solo muestra piezas que hayan alcanzado la etapa
//   "terminado" y que tengan existencia mayor a cero (el taller no vende lo que no tiene).

import '../../produccion/models/etapa_produccion.dart';

/// Excepción base para operaciones del catálogo y carrito de compras.
class CatalogoException implements Exception {
  const CatalogoException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Excepción cuando se intenta adquirir o publicar una pieza que no cumple
/// con las condiciones de venta (etapa terminado y existencia > 0).
class PiezaNoDisponibleException extends CatalogoException {
  const PiezaNoDisponibleException([
    super.message =
        'La pieza solicitada no está terminada o no cuenta con existencia disponible.',
  ]);
}

/// Excepción cuando la cantidad solicitada supera la existencia actual del taller.
class StockInsuficienteException extends CatalogoException {
  const StockInsuficienteException({
    required this.nombrePieza,
    required this.disponible,
  }) : super(
          'Stock insuficiente: solo hay $disponible unidades disponibles de "$nombrePieza".',
        );

  final String nombrePieza;
  final int disponible;
}

/// Entidad inmutable de una pieza dentro del catálogo comercial de Barro Vivo.
class PiezaCatalogo {
  const PiezaCatalogo({
    required this.id,
    required this.loteId,
    required this.loteCodigo,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.etapaActual,
    required this.existencia,
    required this.precioUnitario,
    this.activo = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Identificador único de la pieza en el catálogo.
  final String id;

  /// Referencia al lote de producción del cual proviene.
  final String loteId;

  /// Código del lote de producción (ej. "LOTE-2024-001").
  final String loteCodigo;

  /// Nombre comercial de la pieza artesanal.
  final String nombre;

  /// Descripción detallada de acabados, técnica o contenido del juego.
  final String descripcion;

  /// Categoría comercial (ej. "Vajillas", "Decoración", "Tazas y Mesa").
  final String categoria;

  /// Etapa productiva actual del lote asociado.
  final EtapaProduccion etapaActual;

  /// Cantidad física disponible para la venta inmediata.
  final int existencia;

  /// Precio unitario de venta al público ($ MXN).
  final double precioUnitario;

  /// Bandera de visibilidad / borrado lógico.
  final bool activo;

  /// Timestamp de creación.
  final DateTime? createdAt;

  /// Timestamp de última actualización.
  final DateTime? updatedAt;

  // ── Regla de Negocio Crítica (HU-08 Criterio 1) ─────────────────────────────

  /// Indica si la pieza ya completó la 5a etapa del oficio artesanal.
  bool get estaTerminada => etapaActual == EtapaProduccion.terminado;

  /// Indica si existe al menos una pieza física disponible para vender.
  bool get tieneExistencia => existencia > 0;

  /// Determina si la pieza puede mostrarse en el catálogo publicado al cliente.
  ///
  /// Regla crítica: solo piezas activas, en etapa [EtapaProduccion.terminado]
  /// y con [existencia] > 0.
  bool get esPublicableEnCatalogo => activo && estaTerminada && tieneExistencia;

  // ── Serialización ───────────────────────────────────────────────────────────

  factory PiezaCatalogo.fromJson(Map<String, dynamic> json) {
    return PiezaCatalogo(
      id: json['id'] as String? ?? '',
      loteId: json['lote_id'] as String? ?? '',
      loteCodigo: json['lote_codigo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      categoria: json['categoria'] as String? ?? 'General',
      etapaActual: EtapaProduccion.fromCodigo(json['etapa_actual'] as String?),
      existencia: (json['existencia'] as num?)?.toInt() ?? 0,
      precioUnitario: (json['precio_unitario'] as num?)?.toDouble() ?? 0.0,
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
      'lote_codigo': loteCodigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'categoria': categoria,
      'etapa_actual': etapaActual.codigo,
      'existencia': existencia,
      'precio_unitario': precioUnitario,
      'activo': activo,
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  PiezaCatalogo copyWith({
    String? id,
    String? loteId,
    String? loteCodigo,
    String? nombre,
    String? descripcion,
    String? categoria,
    EtapaProduccion? etapaActual,
    int? existencia,
    double? precioUnitario,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PiezaCatalogo(
      id: id ?? this.id,
      loteId: loteId ?? this.loteId,
      loteCodigo: loteCodigo ?? this.loteCodigo,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      categoria: categoria ?? this.categoria,
      etapaActual: etapaActual ?? this.etapaActual,
      existencia: existencia ?? this.existencia,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PiezaCatalogo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

