// lib/features/mermas/repositories/mermas_repository.dart
//
// Capa de acceso a datos para el registro de mermas de lotes con evidencia
// fotográfica obligatoria y costo estimado por insumos consumidos (HU-06).
// Patrón Repository: interfaz abstracta + implementación concreta Supabase con fallback.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../services/supabase_service.dart';
import '../../produccion/models/etapa_produccion.dart';
import '../models/insumo_consumido_merma.dart';
import '../models/motivo_merma.dart';
import '../models/registro_merma.dart';

// ── Excepciones del Dominio de Mermas ─────────────────────────────────────────

/// Excepción base para operaciones del módulo de mermas.
class MermaException implements Exception {
  const MermaException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Error de red o conexión al consultar o persistir mermas.
class NetworkMermaException extends MermaException {
  const NetworkMermaException(String detail)
      : super('Error de conexión en el módulo de mermas: $detail');
}

/// No se encontró el registro de merma solicitado.
class MermaNotFoundException extends MermaException {
  const MermaNotFoundException([String? id])
      : super('No se encontró el registro de merma${id != null ? ' con ID "$id"' : ''}.');
}

// ── Contrato Abstracto ────────────────────────────────────────────────────────

abstract class MermasRepository {
  /// Obtiene la lista de mermas registradas en el taller, opcionalmente filtradas por [loteId].
  Future<List<RegistroMerma>> getMermas({
    String? loteId,
    bool soloActivos = true,
  });

  /// Registra una nueva merma en un lote de producción.
  ///
  /// Cumple con:
  /// - Criterio 1: Piezas perdidas indicando etapa del daño y motivo (despostillado, rotura, etc.).
  /// - Criterio 2: Obligatorio adjuntar evidencia fotográfica del daño ([evidenciaUrl] no vacío).
  /// - Criterio 3: Calcula el costo estimado según los [insumosConsumidos].
  Future<RegistroMerma> registrarMerma({
    required String loteId,
    required String loteCodigo,
    required EtapaProduccion etapa,
    required MotivoMerma motivo,
    required int cantidadPiezas,
    required String evidenciaUrl,
    required List<InsumoConsumidoMerma> insumosConsumidos,
    required DateTime fecha,
    String? evidenciaDescripcion,
    String? observaciones,
  });

  /// Da de baja lógica un registro de merma (activo = false).
  Future<void> darDeBajaMerma(String id);
}

// ── Implementación Concreta (Supabase) ─────────────────────────────────────────

class SupabaseMermasRepository implements MermasRepository {
  SupabaseMermasRepository({this.client}) {
    _inicializarDatosSemilla();
  }

  final supa.SupabaseClient? client;
  supa.SupabaseClient get _resolvedClient => client ?? SupabaseService.client;

  static const String _tablaMermas = 'lotes_mermas';

  // Memoria local de respaldo con datos realistas del taller
  final List<RegistroMerma> _memoriaMermas = [];

  void _inicializarDatosSemilla() {
    if (_memoriaMermas.isNotEmpty) return;

    final ahora = DateTime.now();

    _memoriaMermas.addAll([
      // Merma 1: Rotura térmica en Jahuete (Horno 1ra quema)
      RegistroMerma(
        id: 'merma_seed_001',
        loteId: 'lote_seed_001',
        loteCodigo: 'LOTE-2024-001 (Vajilla Clásica)',
        etapa: EtapaProduccion.jahuete,
        motivo: MotivoMerma.grietaTermica,
        cantidadPiezas: 4,
        evidenciaUrl: 'evidencia://taller/mermas/jahuete_grieta_termica_001.jpg',
        evidenciaDescripcion: 'Fotografía de 4 platos con fisura radial tras abrir el horno de bizcocho.',
        insumosConsumidos: InsumoConsumidoMerma.plantillaPorEtapa(EtapaProduccion.jahuete),
        observaciones: 'Incremento brusco de temperatura en la zona inferior del horno.',
        fecha: ahora.subtract(const Duration(days: 14)),
        createdAt: ahora.subtract(const Duration(days: 14)),
      ),

      // Merma 2: Despostillado en Decorado
      RegistroMerma(
        id: 'merma_seed_002',
        loteId: 'lote_seed_001',
        loteCodigo: 'LOTE-2024-001 (Vajilla Clásica)',
        etapa: EtapaProduccion.decorado,
        motivo: MotivoMerma.despostillado,
        cantidadPiezas: 2,
        evidenciaUrl: 'evidencia://taller/mermas/decorado_despostillado_002.jpg',
        evidenciaDescripcion: 'Fotografía de detalle de borde despostillado en sopera ya esmaltada y plumeada.',
        insumosConsumidos: InsumoConsumidoMerma.plantillaPorEtapa(EtapaProduccion.decorado),
        observaciones: 'Roce accidental en mesa de trabajo durante el secado de pigmento cobalto.',
        fecha: ahora.subtract(const Duration(days: 8)),
        createdAt: ahora.subtract(const Duration(days: 8)),
      ),

      // Merma 3: Rotura en Esmaltado
      RegistroMerma(
        id: 'merma_seed_003',
        loteId: 'lote_seed_002',
        loteCodigo: 'LOTE-2024-002 (Juego de Tazas)',
        etapa: EtapaProduccion.esmaltado,
        motivo: MotivoMerma.rotura,
        cantidadPiezas: 4,
        evidenciaUrl: 'evidencia://taller/mermas/esmaltado_rotura_asa_003.jpg',
        evidenciaDescripcion: 'Evidencia fotográfica de asas desprendidas durante la inmersión en tina de esmalte.',
        insumosConsumidos: InsumoConsumidoMerma.plantillaPorEtapa(EtapaProduccion.esmaltado),
        observaciones: 'Unión de barbotina débil en las asas antes del baño blanco.',
        fecha: ahora.subtract(const Duration(days: 5)),
        createdAt: ahora.subtract(const Duration(days: 5)),
      ),
    ]);
  }

  @override
  Future<List<RegistroMerma>> getMermas({
    String? loteId,
    bool soloActivos = true,
  }) async {
    try {
      var query = _resolvedClient.from(_tablaMermas).select();

      if (soloActivos) {
        query = query.eq('activo', true);
      }
      if (loteId != null && loteId.trim().isNotEmpty) {
        query = query.eq('lote_id', loteId.trim());
      }

      final List<dynamic> response = await query.order('fecha', ascending: false);

      final remotas = response
          .map((item) => RegistroMerma.fromJson(item as Map<String, dynamic>))
          .toList();

      if (remotas.isNotEmpty) {
        if (loteId == null) {
          _memoriaMermas
            ..clear()
            ..addAll(remotas);
        } else {
          for (final r in remotas) {
            _actualizarEnMemoria(r);
          }
        }
        return remotas;
      }
    } catch (e) {
      debugPrint('[SupabaseMermasRepository] Usando memoria de respaldo por: $e');
    }

    Iterable<RegistroMerma> resultado = _memoriaMermas;
    if (soloActivos) {
      resultado = resultado.where((m) => m.activo);
    }
    if (loteId != null && loteId.trim().isNotEmpty) {
      resultado = resultado.where((m) => m.loteId == loteId.trim());
    }

    final lista = resultado.toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    return List.unmodifiable(lista);
  }

  @override
  Future<RegistroMerma> registrarMerma({
    required String loteId,
    required String loteCodigo,
    required EtapaProduccion etapa,
    required MotivoMerma motivo,
    required int cantidadPiezas,
    required String evidenciaUrl,
    required List<InsumoConsumidoMerma> insumosConsumidos,
    required DateTime fecha,
    String? evidenciaDescripcion,
    String? observaciones,
  }) async {
    final timestamp = DateTime.now();

    final candidata = RegistroMerma(
      id: 'merma_${timestamp.microsecondsSinceEpoch}',
      loteId: loteId.trim(),
      loteCodigo: loteCodigo.trim(),
      etapa: etapa,
      motivo: motivo,
      cantidadPiezas: cantidadPiezas,
      evidenciaUrl: evidenciaUrl.trim(),
      evidenciaDescripcion: evidenciaDescripcion?.trim(),
      insumosConsumidos: insumosConsumidos,
      observaciones: observaciones?.trim(),
      fecha: fecha,
      activo: true,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    // Validación innegociable de reglas de negocio (Criterios 1, 2 y 3)
    candidata.validarReglasDeNegocio();

    try {
      final response = await _resolvedClient
          .from(_tablaMermas)
          .insert(candidata.toJson(includeId: false))
          .select()
          .single();

      final guardada = RegistroMerma.fromJson(response);
      _actualizarEnMemoria(guardada);
      return guardada;
    } catch (e) {
      debugPrint('[SupabaseMermasRepository] Fallback local al registrar merma: $e');
      _actualizarEnMemoria(candidata);
      return candidata;
    }
  }

  @override
  Future<void> darDeBajaMerma(String id) async {
    try {
      await _resolvedClient.from(_tablaMermas).update({
        'activo': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      debugPrint('[SupabaseMermasRepository] Fallback baja local de merma: $e');
    }

    final index = _memoriaMermas.indexWhere((m) => m.id == id);
    if (index != -1) {
      _memoriaMermas[index] = _memoriaMermas[index].copyWith(activo: false);
    }
  }

  void _actualizarEnMemoria(RegistroMerma merma) {
    final index = _memoriaMermas.indexWhere((m) => m.id == merma.id);
    if (index != -1) {
      _memoriaMermas[index] = merma;
    } else {
      _memoriaMermas.insert(0, merma);
    }
  }
}

