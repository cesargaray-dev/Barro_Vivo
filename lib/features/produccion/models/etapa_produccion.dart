// lib/features/produccion/models/etapa_produccion.dart
//
// Enumeración de las cinco etapas estrictas del oficio de talavera tradicional – HU-05.
//
// Secuencia obligatoria:
//   1. Barro crudo (moldeado y secado)
//   2. Jahuete (primera quema / bizcocho)
//   3. Esmaltado (baño de esmalte blanco tradicional)
//   4. Decorado (pintado a mano con óxidos minerales)
//   5. Terminado (segunda quema final y control de calidad)

import 'package:flutter/material.dart';

/// Las cinco etapas estrictas del proceso artesanal de talavera.
enum EtapaProduccion {
  barroCrudo(
    codigo: 'barro_crudo',
    titulo: 'Barro crudo',
    descripcion: 'Modelado, torneado y secado natural de las piezas.',
    orden: 1,
  ),
  jahuete(
    codigo: 'jahuete',
    titulo: 'Jahuete',
    descripcion: 'Primera cocción en horno; pieza porosa lista para esmaltar.',
    orden: 2,
  ),
  esmaltado(
    codigo: 'esmaltado',
    titulo: 'Esmaltado',
    descripcion: 'Inmersión manual en la base de esmalte blanco estannífero.',
    orden: 3,
  ),
  decorado(
    codigo: 'decorado',
    titulo: 'Decorado',
    descripcion: 'Pintado a mano alzada con pinceles y pigmentos tradicionales.',
    orden: 4,
  ),
  terminado(
    codigo: 'terminado',
    titulo: 'Terminado',
    descripcion: 'Segunda quema a gran fuego (1050°C) y pieza lista para entrega.',
    orden: 5,
  );

  const EtapaProduccion({
    required this.codigo,
    required this.titulo,
    required this.descripcion,
    required this.orden,
  });

  /// Identificador textual para persistencia en Supabase / JSON.
  final String codigo;

  /// Nombre legible en la interfaz de usuario.
  final String titulo;

  /// Breve explicación del proceso técnico en el taller.
  final String descripcion;

  /// Orden secuencial (1 al 5).
  final int orden;

  /// Determina la etapa siguiente inmediata en la secuencia estricta.
  ///
  /// Retorna `null` si la etapa actual ya es [EtapaProduccion.terminado].
  EtapaProduccion? get siguiente {
    return switch (this) {
      EtapaProduccion.barroCrudo => EtapaProduccion.jahuete,
      EtapaProduccion.jahuete => EtapaProduccion.esmaltado,
      EtapaProduccion.esmaltado => EtapaProduccion.decorado,
      EtapaProduccion.decorado => EtapaProduccion.terminado,
      EtapaProduccion.terminado => null,
    };
  }

  /// Indica si la etapa es la última del oficio artesanal.
  bool get esUltima => this == EtapaProduccion.terminado;

  /// Valida si es legal la transición desde la etapa actual hacia [destino].
  ///
  /// La regla de negocio de HU-05 exige que únicamente se avance
  /// a la etapa inmediata siguiente:
  /// barro crudo -> jahuete -> esmaltado -> decorado -> terminado.
  bool puedeTransicionarA(EtapaProduccion destino) {
    return siguiente == destino;
  }

  /// Color representativo de la etapa para la interfaz del artesano.
  Color get color {
    return switch (this) {
      EtapaProduccion.barroCrudo => const Color(0xFF8D6E63), // Tono arcilla/tierra
      EtapaProduccion.jahuete => const Color(0xFFC1440E),    // Terracota horneada
      EtapaProduccion.esmaltado => const Color(0xFF455A64),  // Gris esmalte húmedo
      EtapaProduccion.decorado => const Color(0xFF1A53A0),   // Azul cobalto de talavera
      EtapaProduccion.terminado => const Color(0xFF2E7D32),  // Verde éxito / completado
    };
  }

  /// Ícono representativo de la etapa.
  IconData get icono {
    return switch (this) {
      EtapaProduccion.barroCrudo => Icons.water_drop_outlined,
      EtapaProduccion.jahuete => Icons.local_fire_department_rounded,
      EtapaProduccion.esmaltado => Icons.format_paint_rounded,
      EtapaProduccion.decorado => Icons.brush_rounded,
      EtapaProduccion.terminado => Icons.verified_rounded,
    };
  }

  /// Obtiene la etapa correspondiente a partir de su [codigo].
  ///
  /// Si el código no coincide, retorna [EtapaProduccion.barroCrudo] como valor seguro.
  static EtapaProduccion fromCodigo(String? codigo) {
    if (codigo == null) return EtapaProduccion.barroCrudo;
    final normalized = codigo.trim().toLowerCase();
    return EtapaProduccion.values.firstWhere(
      (e) => e.codigo == normalized,
      orElse: () => EtapaProduccion.barroCrudo,
    );
  }
}
