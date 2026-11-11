// lib/features/inventario/repositories/insumos_repository.dart
//
// Capa de acceso a datos para la gestión de insumos (materias primas) – HU-03.
// Sigue el patrón Repository: interfaz abstracta + implementación con Supabase.

import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:barro_vivo/services/supabase_service.dart';
import '../models/materia_prima.dart';

// ── Excepciones del dominio ───────────────────────────────────────────────────

/// Excepción base para operaciones del módulo de inventario.
class InsumoException implements Exception {
  const InsumoException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Fallo al conectar o consultar el servicio de base de datos.
class NetworkInsumoException extends InsumoException {
  const NetworkInsumoException(String detail)
      : super('Error de conexión con el inventario. Verifica tu conexión e intenta de nuevo.');
}

/// Insumo no encontrado en la base de datos.
class InsumoNotFoundException extends InsumoException {
  const InsumoNotFoundException()
      : super('La materia prima no existe o fue dada de baja.');
}

// ── Interfaz ─────────────────────────────────────────────────────────────────

/// Contrato del repositorio para gestionar materias primas.
abstract class InsumosRepository {
  /// Obtiene la lista de materias primas activas ordenadas alfabéticamente por nombre.
  Future<List<MateriaPrima>> getMateriasPrimas();

  /// Registra una nueva materia prima en el inventario.
  Future<MateriaPrima> crearMateriaPrima({
    required String nombre,
    required UnidadMedida unidad,
    required double stockActual,
    required double stockMinimo,
  });

  /// Actualiza los datos de una materia prima existente.
  Future<MateriaPrima> actualizarMateriaPrima(MateriaPrima materiaPrima);

  /// Da de baja lógica una materia prima estableciendo su campo `activo` en false.
  Future<void> darDeBajaMateriaPrima(String id);
}

// ── Implementación con Supabase ──────────────────────────────────────────────

/// Implementación concreta de [InsumosRepository] conectada a Supabase.
class SupabaseInsumosRepository implements InsumosRepository {
  SupabaseInsumosRepository({this.client});

  final supa.SupabaseClient? client;
  supa.SupabaseClient get _resolvedClient => client ?? SupabaseService.client;
  static const String _tabla = 'materias_primas';

  @override
  Future<List<MateriaPrima>> getMateriasPrimas() async {
    try {
      final List<dynamic> response = await _resolvedClient
          .from(_tabla)
          .select()
          .eq('activo', true)
          .order('nombre', ascending: true);

      return response
          .map((item) => MateriaPrima.fromJson(item as Map<String, dynamic>))
          .toList();
    } on supa.PostgrestException catch (e) {
      throw NetworkInsumoException(e.message);
    } catch (e) {
      throw NetworkInsumoException(e.toString());
    }
  }

  @override
  Future<MateriaPrima> crearMateriaPrima({
    required String nombre,
    required UnidadMedida unidad,
    required double stockActual,
    required double stockMinimo,
  }) async {
    try {
      final payload = {
        'nombre': nombre.trim(),
        'unidad': unidad.codigo,
        'stock_actual': stockActual,
        'stock_minimo': stockMinimo,
        'activo': true,
      };

      final response = await _resolvedClient
          .from(_tabla)
          .insert(payload)
          .select()
          .single();

      return MateriaPrima.fromJson(response);
    } on supa.PostgrestException catch (e) {
      throw NetworkInsumoException(e.message);
    } catch (e) {
      throw NetworkInsumoException(e.toString());
    }
  }

  @override
  Future<MateriaPrima> actualizarMateriaPrima(MateriaPrima materiaPrima) async {
    try {
      final payload = {
        'nombre': materiaPrima.nombre.trim(),
        'unidad': materiaPrima.unidad.codigo,
        'stock_actual': materiaPrima.stockActual,
        'stock_minimo': materiaPrima.stockMinimo,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      final response = await _resolvedClient
          .from(_tabla)
          .update(payload)
          .eq('id', materiaPrima.id)
          .select()
          .single();

      return MateriaPrima.fromJson(response);
    } on supa.PostgrestException catch (e) {
      throw NetworkInsumoException(e.message);
    } catch (e) {
      throw NetworkInsumoException(e.toString());
    }
  }

  @override
  Future<void> darDeBajaMateriaPrima(String id) async {
    try {
      await _resolvedClient.from(_tabla).update({
        'activo': false,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } on supa.PostgrestException catch (e) {
      throw NetworkInsumoException(e.message);
    } catch (e) {
      throw NetworkInsumoException(e.toString());
    }
  }
}
