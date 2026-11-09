// lib/features/mermas/models/motivo_merma.dart
//
// Enumerador de dominio para los motivos de merma o pérdida en el taller
// de talavera artesanal (HU-06 – Criterio 1).
//
// Regla arquitectónica: Modelo de dominio puro sin dependencias de UI (material.dart).

/// Causas típicas de pérdida o daño de piezas en las 5 etapas del oficio de talavera.
enum MotivoMerma {
  despostillado(
    codigo: 'despostillado',
    etiqueta: 'Despostillado',
    descripcion: 'Astilladura en bordes, bocas o asas por contacto o manipulación.',
  ),
  rotura(
    codigo: 'rotura',
    etiqueta: 'Rotura',
    descripcion: 'Quiebre parcial o fractura total de la pieza cerámica.',
  ),
  grietaTermica(
    codigo: 'grieta_termica',
    etiqueta: 'Grieta térmica',
    descripcion: 'Fisura por choque térmico durante el horneado (jahuete o gran fuego).',
  ),
  defectoEsmalte(
    codigo: 'defecto_esmalte',
    etiqueta: 'Defecto de esmalte',
    descripcion: 'Escurrimiento, burbujeo o calvas en el baño de esmalte estannífero.',
  ),
  deformacion(
    codigo: 'deformacion',
    etiqueta: 'Deformación',
    descripcion: 'Pandeo o colapso estructural durante el secado o la cocción.',
  ),
  contaminacionPigmento(
    codigo: 'contaminacion_pigmento',
    etiqueta: 'Defecto de decorado',
    descripcion: 'Mancha irreversible o contaminación en los óxidos minerales.',
  ),
  otro(
    codigo: 'otro',
    etiqueta: 'Otro motivo',
    descripcion: 'Otro incidente o daño imprevisto durante la producción.',
  );

  const MotivoMerma({
    required this.codigo,
    required this.etiqueta,
    required this.descripcion,
  });

  /// Identificador para persistencia en Supabase / JSON.
  final String codigo;

  /// Nombre legible del motivo de merma.
  final String etiqueta;

  /// Descripción técnica del daño en el taller.
  final String descripcion;

  /// Obtiene el motivo de merma a partir de su [codigo] persistido.
  static MotivoMerma fromCodigo(String? codigo) {
    if (codigo == null || codigo.trim().isEmpty) {
      return MotivoMerma.rotura;
    }
    final normalized = codigo.trim().toLowerCase();
    return MotivoMerma.values.firstWhere(
      (m) => m.codigo == normalized,
      orElse: () => MotivoMerma.otro,
    );
  }
}

