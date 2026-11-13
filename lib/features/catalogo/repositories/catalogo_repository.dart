// lib/features/catalogo/repositories/catalogo_repository.dart
//
// Capa de acceso a datos para el catálogo de piezas terminadas (HU-08).
// Sigue el patrón Repository: interfaz abstracta + implementación concreta Supabase
// con memoria local de respaldo y cumplimiento estricto de la regla de publicación.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../services/supabase_service.dart';
import '../../produccion/models/etapa_produccion.dart';
import '../models/pieza_catalogo.dart';

/// Contrato abstracto del repositorio de catálogo comercial.
abstract class CatalogoRepository {
  /// Retorna todas las piezas registradas en taller (incluyendo no terminadas o agotadas)
  /// para validación interna y pruebas de filtrado.
  Future<List<PiezaCatalogo>> getTodasLasPiezas();

  /// Retorna únicamente el catálogo publicado al cliente:
  /// etapa "terminado" y existencia mayor a cero.
  Future<List<PiezaCatalogo>> getCatalogoPublicado();

  /// Descuenta [cantidad] unidades de existencia al confirmar un pedido.
  Future<PiezaCatalogo> descontarExistencia({
    required String piezaId,
    required int cantidad,
  });
}

/// Implementación concreta contra Supabase con respaldo en memoria local.
class SupabaseCatalogoRepository implements CatalogoRepository {
  SupabaseCatalogoRepository({this.client}) {
    _inicializarDatosSemilla();
  }

  final supa.SupabaseClient? client;
  supa.SupabaseClient get _resolvedClient => client ?? SupabaseService.client;

  static const String _tablaCatalogo = 'catalogo_piezas';

  final List<PiezaCatalogo> _memoriaPiezas = [];

  void _inicializarDatosSemilla() {
    if (_memoriaPiezas.isNotEmpty) return;

    final ahora = DateTime.now();

    _memoriaPiezas.addAll([
      // ── Piezas publicables (etapa == terminado && existencia > 0) ───────────
      PiezaCatalogo(
        id: 'cat_001',
        loteId: 'lote_seed_001',
        loteCodigo: 'LOTE-2024-001',
        nombre: 'Vajilla Clásica 6 Servicios',
        descripcion:
            'Vajilla artesanal de 24 piezas con grecas azul cobalto pintadas a mano en Dolores Hidalgo.',
        categoria: 'Vajillas',
        etapaActual: EtapaProduccion.terminado,
        existencia: 8,
        precioUnitario: 1850.00,
        createdAt: ahora.subtract(const Duration(days: 15)),
      ),
      PiezaCatalogo(
        id: 'cat_002',
        loteId: 'lote_seed_005',
        loteCodigo: 'LOTE-2024-005',
        nombre: 'Tibores Coloniales Azul Cobalto',
        descripcion:
            'Par de tibores torneados y esmaltados a gran fuego (1050 °C) con tapa tradicional.',
        categoria: 'Decoración',
        etapaActual: EtapaProduccion.terminado,
        existencia: 5,
        precioUnitario: 920.00,
        createdAt: ahora.subtract(const Duration(days: 12)),
      ),
      PiezaCatalogo(
        id: 'cat_003',
        loteId: 'lote_seed_006',
        loteCodigo: 'LOTE-2024-006',
        nombre: 'Juego de Tazas Cacatúa (6 pzas)',
        descripcion:
            'Seis tazas de barro bruñido y esmalte blanco estannífero con motivos florales.',
        categoria: 'Tazas y Mesa',
        etapaActual: EtapaProduccion.terminado,
        existencia: 14,
        precioUnitario: 640.00,
        createdAt: ahora.subtract(const Duration(days: 10)),
      ),
      PiezaCatalogo(
        id: 'cat_004',
        loteId: 'lote_seed_007',
        loteCodigo: 'LOTE-2024-007',
        nombre: 'Platón Ceremonial Flor de Liz',
        descripcion:
            'Platón ovalado de 42 cm decorado con pigmentos minerales tradicionales.',
        categoria: 'Mesa y Cocina',
        etapaActual: EtapaProduccion.terminado,
        existencia: 4,
        precioUnitario: 780.00,
        createdAt: ahora.subtract(const Duration(days: 8)),
      ),
      PiezaCatalogo(
        id: 'cat_005',
        loteId: 'lote_seed_008',
        loteCodigo: 'LOTE-2024-008',
        nombre: 'Caja de Azulejos Mayólica (20 pzas)',
        descripcion:
            'Azulejos cuadrados 10x10 cm listos para instalación en muros o fuentes.',
        categoria: 'Murales y Azulejos',
        etapaActual: EtapaProduccion.terminado,
        existencia: 12,
        precioUnitario: 1100.00,
        createdAt: ahora.subtract(const Duration(days: 6)),
      ),

      // ── Piezas NO publicables (regla crítica: ocultas al cliente) ──────────
      PiezaCatalogo(
        id: 'cat_006',
        loteId: 'lote_seed_002',
        loteCodigo: 'LOTE-2024-002',
        nombre: 'Juego de Tazas Grecas (En taller)',
        descripcion:
            'En proceso de decorado manual; aún no entra a segunda quema.',
        categoria: 'Tazas y Mesa',
        etapaActual: EtapaProduccion.decorado,
        existencia: 36,
        precioUnitario: 580.00,
        createdAt: ahora.subtract(const Duration(days: 4)),
      ),
      PiezaCatalogo(
        id: 'cat_007',
        loteId: 'lote_seed_003',
        loteCodigo: 'LOTE-2024-003',
        nombre: 'Florero Cervantino Gran Formato',
        descripcion: 'En etapa de jahuete tras primera cocción.',
        categoria: 'Decoración',
        etapaActual: EtapaProduccion.jahuete,
        existencia: 12,
        precioUnitario: 480.00,
        createdAt: ahora.subtract(const Duration(days: 3)),
      ),
      PiezaCatalogo(
        id: 'cat_008',
        loteId: 'lote_seed_009',
        loteCodigo: 'LOTE-2024-009',
        nombre: 'Licorera Tradicional Edición Especial',
        descripcion: 'Lote terminado pero actualmente sin unidades en existencia.',
        categoria: 'Decoración',
        etapaActual: EtapaProduccion.terminado,
        existencia: 0,
        precioUnitario: 690.00,
        createdAt: ahora.subtract(const Duration(days: 20)),
      ),
    ]);
  }

  @override
  Future<List<PiezaCatalogo>> getTodasLasPiezas() async {
    try {
      final response = await _resolvedClient
          .from(_tablaCatalogo)
          .select()
          .eq('activo', true)
          .order('created_at', ascending: false);

      final remotos = (response as List)
          .map((item) => PiezaCatalogo.fromJson(item as Map<String, dynamic>))
          .toList();

      if (remotos.isNotEmpty) {
        _memoriaPiezas
          ..clear()
          ..addAll(remotos);
        return List.unmodifiable(_memoriaPiezas);
      }
    } catch (e) {
      debugPrint(
        '[SupabaseCatalogoRepository] Usando memoria de respaldo al consultar catálogo: $e',
      );
    }

    return List.unmodifiable(_memoriaPiezas);
  }

  @override
  Future<List<PiezaCatalogo>> getCatalogoPublicado() async {
    final todas = await getTodasLasPiezas();
    return todas.where((p) => p.esPublicableEnCatalogo).toList();
  }

  @override
  Future<PiezaCatalogo> descontarExistencia({
    required String piezaId,
    required int cantidad,
  }) async {
    if (cantidad <= 0) {
      throw const CatalogoException(
        'La cantidad a descontar debe ser mayor a cero.',
      );
    }

    final idx = _memoriaPiezas.indexWhere((p) => p.id == piezaId);
    if (idx == -1) {
      throw const PiezaNoDisponibleException();
    }

    final actual = _memoriaPiezas[idx];
    if (!actual.estaTerminada) {
      throw const PiezaNoDisponibleException(
        'No se puede vender una pieza que no ha alcanzado la etapa terminado.',
      );
    }
    if (actual.existencia < cantidad) {
      throw StockInsuficienteException(
        nombrePieza: actual.nombre,
        disponible: actual.existencia,
      );
    }

    final nuevaExistencia = actual.existencia - cantidad;
    final actualizada = actual.copyWith(
      existencia: nuevaExistencia,
      updatedAt: DateTime.now(),
    );

    try {
      await _resolvedClient.from(_tablaCatalogo).update({
        'existencia': nuevaExistencia,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', piezaId);
    } catch (e) {
      debugPrint(
        '[SupabaseCatalogoRepository] Descuento actualizado en memoria local: $e',
      );
    }

    _memoriaPiezas[idx] = actualizada;
    return actualizada;
  }
}

