// lib/features/finanzas/repositories/finanzas_repository.dart
//
// Capa de acceso a datos para costos de producción, mermas prorrateadas y utilidad (HU-07).
// Sigue el patrón Repository: interfaz abstracta + implementación concreta Supabase con fallback.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../services/supabase_service.dart';
import '../../produccion/models/etapa_produccion.dart';
import '../models/analisis_financiero_lote.dart';
import '../models/categoria_costo.dart';
import '../models/item_desglose_costo.dart';
import '../models/resumen_financiero_global.dart';

// ── Excepciones del Dominio Financiero ────────────────────────────────────────

/// Excepción base para operaciones del módulo financiero.
class FinanzasException implements Exception {
  const FinanzasException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Fallo de red o comunicación con el backend al consultar finanzas.
class NetworkFinanzasException extends FinanzasException {
  const NetworkFinanzasException(String detail)
      : super('Error de conexión en el módulo financiero: $detail');
}

/// No se encontró el registro de costos del lote solicitado.
class AnalisisNotFoundException extends FinanzasException {
  const AnalisisNotFoundException([String? id])
      : super('No se encontró el análisis de costos para el lote con ID "$id".');
}

// ── Contrato Abstracto ────────────────────────────────────────────────────────

abstract class FinanzasRepository {
  /// Obtiene la lista completa de análisis financieros de los lotes del taller.
  Future<List<AnalisisFinancieroLote>> getAnalisisFinanciero({bool soloActivos = true});

  /// Obtiene el análisis financiero de un lote específico por su ID.
  Future<AnalisisFinancieroLote> getAnalisisPorLoteId(String loteId);

  /// Actualiza el precio de venta unitario sugerido para un lote y recalcula utilidad.
  Future<AnalisisFinancieroLote> actualizarPrecioVenta({
    required String loteId,
    required double nuevoPrecio,
  });

  /// Registra o actualiza el análisis financiero de un lote.
  Future<AnalisisFinancieroLote> guardarAnalisis(AnalisisFinancieroLote analisis);

  /// Obtiene el resumen financiero global consolidado para el dueño del taller.
  Future<ResumenFinancieroGlobal> getResumenGlobal();
}

// ── Implementación Concreta (Supabase) ─────────────────────────────────────────

class SupabaseFinanzasRepository implements FinanzasRepository {
  SupabaseFinanzasRepository({this.client}) {
    _inicializarDatosSemilla();
  }

  final supa.SupabaseClient? client;
  supa.SupabaseClient get _resolvedClient => client ?? SupabaseService.client;

  static const String _tablaFinanzas = 'lotes_finanzas';

  // Memoria local de respaldo con datos de prueba realistas de talavera
  final List<AnalisisFinancieroLote> _memoriaFinanzas = [];

  void _inicializarDatosSemilla() {
    if (_memoriaFinanzas.isNotEmpty) return;

    final ahora = DateTime.now();

    _memoriaFinanzas.addAll([
      // Lote 1: Terminado, alta rentabilidad
      AnalisisFinancieroLote(
        id: 'fin_001',
        loteId: 'lote_seed_001',
        loteCodigo: 'LOTE-2024-001 (Vajilla Clásica)',
        descripcion: 'Vajilla artesanal de 6 servicios con motivos tradicionales de Dolores Hidalgo.',
        etapaActual: EtapaProduccion.terminado,
        cantidadPiezasIniciales: 60,
        piezasMermadas: 6,
        gastoMateriaPrimaTotal: 3600.0, // $60 MP por pieza inicial
        costoMermasTotal: 450.0,        // Mermas acumuladas en horno y decorado
        precioVentaUnitario: 180.0,     // Precio al público
        fechaCreacion: ahora.subtract(const Duration(days: 20)),
        desgloseCategorias: const [
          ItemDesgloseCosto(categoria: CategoriaCosto.barroPastas, monto: 1260.0),
          ItemDesgloseCosto(categoria: CategoriaCosto.esmaltesVidriado, monto: 900.0),
          ItemDesgloseCosto(categoria: CategoriaCosto.pigmentosDecorado, monto: 720.0),
          ItemDesgloseCosto(categoria: CategoriaCosto.horneadoEnergia, monto: 720.0),
          ItemDesgloseCosto(categoria: CategoriaCosto.mermaProrrateada, monto: 450.0),
        ],
      ),

      // Lote 2: En decorado, excelente margen
      AnalisisFinancieroLote(
        id: 'fin_002',
        loteId: 'lote_seed_002',
        loteCodigo: 'LOTE-2024-002 (Juego de Tazas)',
        descripcion: 'Juego de 40 tazas decoradas a mano con grecas azul cobalto.',
        etapaActual: EtapaProduccion.decorado,
        cantidadPiezasIniciales: 40,
        piezasMermadas: 4,
        gastoMateriaPrimaTotal: 2160.0,
        costoMermasTotal: 270.0,
        precioVentaUnitario: 150.0,
        fechaCreacion: ahora.subtract(const Duration(days: 12)),
        desgloseCategorias: const [
          ItemDesgloseCosto(categoria: CategoriaCosto.barroPastas, monto: 756.0),
          ItemDesgloseCosto(categoria: CategoriaCosto.esmaltesVidriado, monto: 540.0),
          ItemDesgloseCosto(categoria: CategoriaCosto.pigmentosDecorado, monto: 432.0),
          ItemDesgloseCosto(categoria: CategoriaCosto.horneadoEnergia, monto: 432.0),
          ItemDesgloseCosto(categoria: CategoriaCosto.mermaProrrateada, monto: 270.0),
        ],
      ),

      // Lote 3: En jahuete, margen saludable
      AnalisisFinancieroLote(
        id: 'fin_003',
        loteId: 'lote_seed_003',
        loteCodigo: 'LOTE-2024-003 (Florero Cervantino)',
        descripcion: 'Florero de gran formato torneado a mano.',
        etapaActual: EtapaProduccion.jahuete,
        cantidadPiezasIniciales: 15,
        piezasMermadas: 3,
        gastoMateriaPrimaTotal: 2880.0,
        costoMermasTotal: 600.0,
        precioVentaUnitario: 480.0,
        fechaCreacion: ahora.subtract(const Duration(days: 5)),
        desgloseCategorias: const [
          ItemDesgloseCosto(categoria: CategoriaCosto.barroPastas, monto: 1008.0),
          ItemDesgloseCosto(categoria: CategoriaCosto.esmaltesVidriado, monto: 720.0),
          ItemDesgloseCosto(categoria: CategoriaCosto.pigmentosDecorado, monto: 576.0),
          ItemDesgloseCosto(categoria: CategoriaCosto.horneadoEnergia, monto: 576.0),
          ItemDesgloseCosto(categoria: CategoriaCosto.mermaProrrateada, monto: 600.0),
        ],
      ),

      // Lote 4: En esmaltado, margen ajustado para advertencia
      AnalisisFinancieroLote(
        id: 'fin_004',
        loteId: 'lote_seed_004',
        loteCodigo: 'LOTE-2024-004 (Azulejos Mayólica)',
        descripcion: 'Azulejos cuadrados 10x10 para mural artesanal.',
        etapaActual: EtapaProduccion.esmaltado,
        cantidadPiezasIniciales: 100,
        piezasMermadas: 10,
        gastoMateriaPrimaTotal: 4500.0,
        costoMermasTotal: 500.0,
        precioVentaUnitario: 65.0, // Costo unitario es $55.56, margen estrecho (14.5%)
        fechaCreacion: ahora.subtract(const Duration(days: 2)),
        desgloseCategorias: const [
          ItemDesgloseCosto(categoria: CategoriaCosto.barroPastas, monto: 1575.0),
          ItemDesgloseCosto(categoria: CategoriaCosto.esmaltesVidriado, monto: 1125.0),
          ItemDesgloseCosto(categoria: CategoriaCosto.pigmentosDecorado, monto: 900.0),
          ItemDesgloseCosto(categoria: CategoriaCosto.horneadoEnergia, monto: 900.0),
          ItemDesgloseCosto(categoria: CategoriaCosto.mermaProrrateada, monto: 500.0),
        ],
      ),
    ]);
  }

  @override
  Future<List<AnalisisFinancieroLote>> getAnalisisFinanciero({bool soloActivos = true}) async {
    try {
      final response = await _resolvedClient
          .from(_tablaFinanzas)
          .select()
          .order('created_at', ascending: false);

      final remoteList = (response as List)
          .map((data) => AnalisisFinancieroLote.fromJson(data as Map<String, dynamic>))
          .toList();

      if (remoteList.isNotEmpty) {
        _memoriaFinanzas
          ..clear()
          ..addAll(remoteList);
        return List.unmodifiable(_memoriaFinanzas);
      }
    } catch (e) {
      debugPrint('SupabaseFinanzasRepository: Usando memoria de respaldo por: $e');
    }

    return List.unmodifiable(_memoriaFinanzas);
  }

  @override
  Future<AnalisisFinancieroLote> getAnalisisPorLoteId(String loteId) async {
    try {
      final response = await _resolvedClient
          .from(_tablaFinanzas)
          .select()
          .eq('lote_id', loteId)
          .maybeSingle();

      if (response != null) {
        return AnalisisFinancieroLote.fromJson(response);
      }
    } catch (e) {
      debugPrint('SupabaseFinanzasRepository: Error al consultar por loteId: $e');
    }

    final local = _memoriaFinanzas.firstWhere(
      (a) => a.loteId == loteId || a.id == loteId,
      orElse: () => throw AnalisisNotFoundException(loteId),
    );
    return local;
  }

  @override
  Future<AnalisisFinancieroLote> actualizarPrecioVenta({
    required String loteId,
    required double nuevoPrecio,
  }) async {
    if (nuevoPrecio < 0.0) {
      throw const FinanzasException('El precio de venta no puede ser negativo.');
    }

    try {
      final response = await _resolvedClient
          .from(_tablaFinanzas)
          .update({
            'precio_venta_unitario': nuevoPrecio,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('lote_id', loteId)
          .select()
          .maybeSingle();

      if (response != null) {
        final actualizado = AnalisisFinancieroLote.fromJson(response);
        _actualizarEnMemoria(actualizado);
        return actualizado;
      }
    } catch (e) {
      debugPrint('SupabaseFinanzasRepository: Actualizando en memoria por fallback: $e');
    }

    final index = _memoriaFinanzas.indexWhere((a) => a.loteId == loteId || a.id == loteId);
    if (index == -1) throw AnalisisNotFoundException(loteId);

    final actualizado = _memoriaFinanzas[index].copyWith(
      precioVentaUnitario: nuevoPrecio,
      updatedAt: DateTime.now(),
    );
    _memoriaFinanzas[index] = actualizado;
    return actualizado;
  }

  @override
  Future<AnalisisFinancieroLote> guardarAnalisis(AnalisisFinancieroLote analisis) async {
    try {
      final response = await _resolvedClient
          .from(_tablaFinanzas)
          .upsert(analisis.toJson(includeId: true))
          .select()
          .single();

      final guardado = AnalisisFinancieroLote.fromJson(response);
      _actualizarEnMemoria(guardado);
      return guardado;
    } catch (e) {
      debugPrint('SupabaseFinanzasRepository: Guardando en memoria por fallback: $e');
      _actualizarEnMemoria(analisis);
      return analisis;
    }
  }

  @override
  Future<ResumenFinancieroGlobal> getResumenGlobal() async {
    final lotes = await getAnalisisFinanciero();
    return ResumenFinancieroGlobal.desdeLotes(lotes);
  }

  void _actualizarEnMemoria(AnalisisFinancieroLote nuevo) {
    final idx = _memoriaFinanzas.indexWhere((a) => a.id == nuevo.id || a.loteId == nuevo.loteId);
    if (idx != -1) {
      _memoriaFinanzas[idx] = nuevo;
    } else {
      _memoriaFinanzas.insert(0, nuevo);
    }
  }
}

