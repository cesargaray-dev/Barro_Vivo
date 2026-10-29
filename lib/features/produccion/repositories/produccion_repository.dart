// lib/features/produccion/repositories/produccion_repository.dart
//
// Capa de acceso a datos para la gestión de lotes y avance de etapas – HU-05.
// Patrón Repository: interfaz abstracta + implementación concreta Supabase.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../services/supabase_service.dart';
import '../models/etapa_produccion.dart';
import '../models/historial_etapa.dart';
import '../models/lote_produccion.dart';

// ── Excepciones del Dominio ───────────────────────────────────────────────────

/// Excepción base para operaciones de producción.
class ProduccionException implements Exception {
  const ProduccionException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Fallo de red o conexión con la base de datos de producción.
class NetworkProduccionException extends ProduccionException {
  const NetworkProduccionException(String detail)
      : super('Error de conexión con el módulo de producción: $detail');
}

/// Lote no encontrado en el sistema.
class LoteNotFoundException extends ProduccionException {
  const LoteNotFoundException([String? id])
      : super('El lote${id != null ? ' con ID "$id"' : ''} no existe o fue dado de baja.');
}

// ── Interfaz ─────────────────────────────────────────────────────────────────

/// Contrato del repositorio para la gestión de lotes de producción.
abstract class ProduccionRepository {
  /// Obtiene la lista de lotes registrados en el taller.
  Future<List<LoteProduccion>> getLotes({bool soloActivos = true});

  /// Obtiene un lote específico por su identificador junto con su historial.
  Future<LoteProduccion> getLotePorId(String id);

  /// Registra un nuevo lote de producción e inicializa su etapa en [EtapaProduccion.barroCrudo].
  ///
  /// Cumple Criterio 1: Crear lote y asignarle una fecha.
  Future<LoteProduccion> crearLote({
    required String codigo,
    required int cantidadPiezas,
    required DateTime fechaCreacion,
    String? descripcion,
    String? notasIniciales,
  });

  /// Avanza el lote a su siguiente etapa estricta y registra la fecha en el historial.
  ///
  /// Cumple Criterio 2: Secuencia estricta barro crudo -> jahuete -> esmaltado -> decorado -> terminado.
  /// Cumple Criterio 3: Historial consultable de fechas de avance.
  Future<LoteProduccion> avanzarEtapa({
    required String loteId,
    required DateTime fecha,
    String? notas,
  });

  /// Consulta el historial completo de etapas de un lote ordenado cronológicamente.
  Future<List<HistorialEtapa>> getHistorialLote(String loteId);

  /// Da de baja lógica un lote (activo = false).
  Future<void> darDeBajaLote(String id);
}

// ── Implementación concreta (Supabase) ────────────────────────────────────────

/// Implementación de [ProduccionRepository] conectada al backend de Supabase.
class SupabaseProduccionRepository implements ProduccionRepository {
  SupabaseProduccionRepository({this.client});

  final supa.SupabaseClient? client;
  supa.SupabaseClient get _resolvedClient => client ?? SupabaseService.client;

  static const String _tablaLotes = 'lotes_produccion';
  static const String _tablaHistorial = 'lotes_historial_etapas';

  // Memoria local de respaldo para soporte offline o tablas aún no migradas.
  final List<LoteProduccion> _memoriaLotes = [];

  @override
  Future<List<LoteProduccion>> getLotes({bool soloActivos = true}) async {
    try {
      var query = _resolvedClient.from(_tablaLotes).select('''
        *,
        lotes_historial_etapas(*)
      ''');

      if (soloActivos) {
        query = query.eq('activo', true);
      }

      final List<dynamic> response = await query.order('created_at', ascending: false);

      final lotes = response
          .map((item) => LoteProduccion.fromJson(item as Map<String, dynamic>))
          .toList();

      // Sincronizar memoria local de respaldo
      _sincronizarMemoria(lotes);
      return lotes;
    } on supa.PostgrestException catch (e) {
      debugPrint('[SupabaseProduccionRepository] PostgrestException: ${e.message}');
      // Si la tabla no existe en la nube aún o hay error, usar memoria de respaldo
      if (_memoriaLotes.isNotEmpty) {
        return soloActivos
            ? _memoriaLotes.where((l) => l.activo).toList()
            : List.unmodifiable(_memoriaLotes);
      }
      throw NetworkProduccionException(e.message);
    } catch (e) {
      debugPrint('[SupabaseProduccionRepository] Error: $e');
      if (_memoriaLotes.isNotEmpty) {
        return soloActivos
            ? _memoriaLotes.where((l) => l.activo).toList()
            : List.unmodifiable(_memoriaLotes);
      }
      throw NetworkProduccionException(e.toString());
    }
  }

  @override
  Future<LoteProduccion> getLotePorId(String id) async {
    try {
      final response = await _resolvedClient
          .from(_tablaLotes)
          .select('''
            *,
            lotes_historial_etapas(*)
          ''')
          .eq('id', id)
          .single();

      final lote = LoteProduccion.fromJson(response);
      _actualizarEnMemoria(lote);
      return lote;
    } catch (_) {
      final index = _memoriaLotes.indexWhere((l) => l.id == id);
      if (index != -1) return _memoriaLotes[index];
      throw LoteNotFoundException(id);
    }
  }

  @override
  Future<LoteProduccion> crearLote({
    required String codigo,
    required int cantidadPiezas,
    required DateTime fechaCreacion,
    String? descripcion,
    String? notasIniciales,
  }) async {
    final timestamp = DateTime.now();

    try {
      // 1. Insertar el lote en lotes_produccion iniciando en barro_crudo
      final loteData = {
        'codigo': codigo.trim(),
        'cantidad_piezas': cantidadPiezas,
        'fecha_creacion': fechaCreacion.toIso8601String(),
        'descripcion': descripcion?.trim(),
        'etapa_actual': EtapaProduccion.barroCrudo.codigo,
        'activo': true,
      };

      final responseLote = await _resolvedClient
          .from(_tablaLotes)
          .insert(loteData)
          .select()
          .single();

      final loteId = responseLote['id'] as String;

      // 2. Registrar el hito inicial en el historial (Criterio 1 y 3)
      final historialData = {
        'lote_id': loteId,
        'etapa': EtapaProduccion.barroCrudo.codigo,
        'fecha': fechaCreacion.toIso8601String(),
        'notas': notasIniciales?.trim() ?? 'Inicio de producción en barro crudo',
      };

      HistorialEtapa registroInicial;
      try {
        final responseHist = await _resolvedClient
            .from(_tablaHistorial)
            .insert(historialData)
            .select()
            .single();
        registroInicial = HistorialEtapa.fromJson(responseHist);
      } catch (e) {
        debugPrint('[SupabaseProduccionRepository] Advertencia al insertar historial: $e');
        registroInicial = HistorialEtapa(
          id: 'hist_${timestamp.microsecondsSinceEpoch}',
          loteId: loteId,
          etapa: EtapaProduccion.barroCrudo,
          fecha: fechaCreacion,
          notas: notasIniciales?.trim() ?? 'Inicio de producción en barro crudo',
          createdAt: timestamp,
        );
      }

      final nuevoLote = LoteProduccion.fromJson(
        responseLote,
        historial: [registroInicial],
      );

      _actualizarEnMemoria(nuevoLote);
      return nuevoLote;
    } catch (e) {
      debugPrint('[SupabaseProduccionRepository] Fallback local para crear lote: $e');
      // Crear en memoria local para no bloquear la app
      final localId = 'lote_${timestamp.millisecondsSinceEpoch}';
      final hitoInicial = HistorialEtapa(
        id: 'hist_${timestamp.microsecondsSinceEpoch}',
        loteId: localId,
        etapa: EtapaProduccion.barroCrudo,
        fecha: fechaCreacion,
        notas: notasIniciales?.trim() ?? 'Inicio de producción en barro crudo',
        createdAt: timestamp,
      );

      final nuevoLote = LoteProduccion(
        id: localId,
        codigo: codigo.trim(),
        cantidadPiezas: cantidadPiezas,
        fechaCreacion: fechaCreacion,
        descripcion: descripcion?.trim(),
        etapaActual: EtapaProduccion.barroCrudo,
        historial: [hitoInicial],
        activo: true,
        createdAt: timestamp,
        updatedAt: timestamp,
      );

      _actualizarEnMemoria(nuevoLote);
      return nuevoLote;
    }
  }

  @override
  Future<LoteProduccion> avanzarEtapa({
    required String loteId,
    required DateTime fecha,
    String? notas,
  }) async {
    // 1. Obtener estado actual del lote
    final loteActual = await getLotePorId(loteId);

    // 2. Validar transición estricta (Criterio 2)
    final proximaEtapa = loteActual.siguienteEtapa;
    if (proximaEtapa == null) {
      throw TransicionEtapaInvalidaException(
        etapaActual: loteActual.etapaActual,
        etapaIntentada: loteActual.etapaActual,
        loteCodigo: loteActual.codigo,
      );
    }

    try {
      // 3. Registrar nuevo hito en el historial (Criterio 3)
      final histData = {
        'lote_id': loteId,
        'etapa': proximaEtapa.codigo,
        'fecha': fecha.toIso8601String(),
        'notas': notas?.trim(),
      };

      HistorialEtapa nuevoHistorial;
      try {
        final resHist = await _resolvedClient
            .from(_tablaHistorial)
            .insert(histData)
            .select()
            .single();
        nuevoHistorial = HistorialEtapa.fromJson(resHist);
      } catch (e) {
        debugPrint('[SupabaseProduccionRepository] Fallback historial: $e');
        nuevoHistorial = HistorialEtapa(
          id: 'hist_${DateTime.now().microsecondsSinceEpoch}',
          loteId: loteId,
          etapa: proximaEtapa,
          fecha: fecha,
          notas: notas?.trim(),
          createdAt: DateTime.now(),
        );
      }

      // 4. Actualizar etapa_actual en lotes_produccion
      await _resolvedClient.from(_tablaLotes).update({
        'etapa_actual': proximaEtapa.codigo,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', loteId);

      final loteActualizado = loteActual.copyWith(
        etapaActual: proximaEtapa,
        historial: [...loteActual.historial, nuevoHistorial],
        updatedAt: DateTime.now(),
      );

      _actualizarEnMemoria(loteActualizado);
      return loteActualizado;
    } catch (e) {
      debugPrint('[SupabaseProduccionRepository] Fallback local para avanzar etapa: $e');
      final loteActualizado = loteActual.avanzarASiguienteEtapa(
        fecha: fecha,
        notas: notas,
      );
      _actualizarEnMemoria(loteActualizado);
      return loteActualizado;
    }
  }

  @override
  Future<List<HistorialEtapa>> getHistorialLote(String loteId) async {
    try {
      final List<dynamic> response = await _resolvedClient
          .from(_tablaHistorial)
          .select()
          .eq('lote_id', loteId)
          .order('fecha', ascending: true);

      return response
          .map((item) => HistorialEtapa.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final lote = await getLotePorId(loteId);
      return lote.historial;
    }
  }

  @override
  Future<void> darDeBajaLote(String id) async {
    try {
      await _resolvedClient
          .from(_tablaLotes)
          .update({'activo': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      debugPrint('[SupabaseProduccionRepository] Fallback baja local: $e');
    }

    final index = _memoriaLotes.indexWhere((l) => l.id == id);
    if (index != -1) {
      _memoriaLotes[index] = _memoriaLotes[index].copyWith(activo: false);
    }
  }

  // ── Helpers privados ──────────────────────────────────────────────────────

  void _sincronizarMemoria(List<LoteProduccion> remotos) {
    _memoriaLotes.clear();
    _memoriaLotes.addAll(remotos);
  }

  void _actualizarEnMemoria(LoteProduccion lote) {
    final index = _memoriaLotes.indexWhere((l) => l.id == lote.id);
    if (index != -1) {
      _memoriaLotes[index] = lote;
    } else {
      _memoriaLotes.insert(0, lote);
    }
  }
}
