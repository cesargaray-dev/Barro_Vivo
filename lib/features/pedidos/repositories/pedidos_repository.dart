// lib/features/pedidos/repositories/pedidos_repository.dart
//
// Capa de acceso a datos para pedidos, emisión de folios consecutivos BV-XXXX
// y transición por la línea de tiempo de estados (HU-09).

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../services/supabase_service.dart';
import '../models/estado_pedido.dart';
import '../models/historial_estado_pedido.dart';
import '../models/item_pedido.dart';
import '../models/pedido.dart';

/// Contrato abstracto del repositorio de pedidos y órdenes del taller.
abstract class PedidosRepository {
  /// Consulta los pedidos registrados. Si se especifica [clienteEmail],
  /// filtra las órdenes pertenecientes a ese cliente ("Mis pedidos").
  Future<List<Pedido>> getPedidos({String? clienteEmail});

  /// Confirma un nuevo pedido asignando un folio consecutivo (`BV-XXXX`)
  /// y estado inicial [EstadoPedido.enEsperaPago].
  Future<Pedido> confirmarPedido({
    required String clienteEmail,
    String? clienteNombre,
    required List<ItemPedido> items,
    required double subtotal,
    required double costoEnvio,
    required double total,
    String? direccionEntrega,
    String? notasCliente,
  });

  /// Avanza un pedido a su estado inmediato siguiente en la línea de tiempo.
  Future<Pedido> avanzarEstadoPedido({
    required String pedidoId,
    String? nota,
  });

  /// Último número consecutivo asignado.
  int get ultimoConsecutivo;
}

/// Implementación concreta contra Supabase con respaldo en memoria local.
class SupabasePedidosRepository implements PedidosRepository {
  SupabasePedidosRepository({this.client}) {
    _inicializarDatosSemilla();
  }

  final supa.SupabaseClient? client;
  supa.SupabaseClient get _resolvedClient => client ?? SupabaseService.client;

  static const String _tablaPedidos = 'pedidos';
  static const String _tablaHistorial = 'pedidos_historial_estados';

  final List<Pedido> _memoriaPedidos = [];
  int _consecutivoActual = 127;

  @override
  int get ultimoConsecutivo => _consecutivoActual;

  void _inicializarDatosSemilla() {
    if (_memoriaPedidos.isNotEmpty) return;

    final ahora = DateTime.now();

    _memoriaPedidos.addAll([
      Pedido(
        id: 'ped_seed_127',
        folio: 'BV-0127',
        numeroConsecutivo: 127,
        clienteEmail: 'cliente@barrovivo.test',
        clienteNombre: 'Ana Sofía Méndez',
        direccionEntrega: 'Av. Juárez 412, Centro, Guanajuato, Gto.',
        estadoActual: EstadoPedido.enPreparacion,
        items: const [
          ItemPedido(
            piezaId: 'cat_002',
            loteCodigo: 'LOTE-2024-005',
            nombrePieza: 'Tibores Coloniales Azul Cobalto',
            cantidad: 1,
            precioUnitario: 920.0,
          ),
          ItemPedido(
            piezaId: 'cat_003',
            loteCodigo: 'LOTE-2024-006',
            nombrePieza: 'Juego de Tazas Cacatúa (6 pzas)',
            cantidad: 1,
            precioUnitario: 640.0,
          ),
        ],
        subtotal: 1560.0,
        costoEnvio: 0.0,
        total: 1560.0,
        fechaCreacion: ahora.subtract(const Duration(days: 2)),
        historialEstados: [
          HistorialEstadoPedido(
            id: 'hp_127_1',
            pedidoId: 'ped_seed_127',
            estado: EstadoPedido.enEsperaPago,
            fecha: ahora.subtract(const Duration(days: 2)),
            nota: 'Pedido confirmado en tienda.',
          ),
          HistorialEstadoPedido(
            id: 'hp_127_2',
            pedidoId: 'ped_seed_127',
            estado: EstadoPedido.pagado,
            fecha: ahora.subtract(const Duration(days: 1, hours: 18)),
            nota: 'Pago verificado por el taller.',
          ),
          HistorialEstadoPedido(
            id: 'hp_127_3',
            pedidoId: 'ped_seed_127',
            estado: EstadoPedido.enPreparacion,
            fecha: ahora.subtract(const Duration(hours: 10)),
            nota: 'Empacando piezas con protección acolchada.',
          ),
        ],
      ),
      Pedido(
        id: 'ped_seed_126',
        folio: 'BV-0126',
        numeroConsecutivo: 126,
        clienteEmail: 'cliente@barrovivo.test',
        clienteNombre: 'Ana Sofía Méndez',
        direccionEntrega: 'Av. Juárez 412, Centro, Guanajuato, Gto.',
        estadoActual: EstadoPedido.entregado,
        items: const [
          ItemPedido(
            piezaId: 'cat_001',
            loteCodigo: 'LOTE-2024-001',
            nombrePieza: 'Vajilla Clásica 6 Servicios',
            cantidad: 1,
            precioUnitario: 1850.0,
          ),
        ],
        subtotal: 1850.0,
        costoEnvio: 0.0,
        total: 1850.0,
        fechaCreacion: ahora.subtract(const Duration(days: 9)),
        historialEstados: [
          HistorialEstadoPedido(
            id: 'hp_126_1',
            pedidoId: 'ped_seed_126',
            estado: EstadoPedido.enEsperaPago,
            fecha: ahora.subtract(const Duration(days: 9)),
          ),
          HistorialEstadoPedido(
            id: 'hp_126_2',
            pedidoId: 'ped_seed_126',
            estado: EstadoPedido.pagado,
            fecha: ahora.subtract(const Duration(days: 8)),
          ),
          HistorialEstadoPedido(
            id: 'hp_126_3',
            pedidoId: 'ped_seed_126',
            estado: EstadoPedido.enPreparacion,
            fecha: ahora.subtract(const Duration(days: 7)),
          ),
          HistorialEstadoPedido(
            id: 'hp_126_4',
            pedidoId: 'ped_seed_126',
            estado: EstadoPedido.enviado,
            fecha: ahora.subtract(const Duration(days: 6)),
            nota: 'Guía de paquetería artesanal asignada.',
          ),
          HistorialEstadoPedido(
            id: 'hp_126_5',
            pedidoId: 'ped_seed_126',
            estado: EstadoPedido.entregado,
            fecha: ahora.subtract(const Duration(days: 4)),
            nota: 'Recibido por el cliente.',
          ),
        ],
      ),
    ]);
  }

  @override
  Future<List<Pedido>> getPedidos({String? clienteEmail}) async {
    try {
      var query = _resolvedClient.from(_tablaPedidos).select();
      if (clienteEmail != null && clienteEmail.trim().isNotEmpty) {
        query = query.eq('cliente_email', clienteEmail.trim());
      }
      final response = await query.order('numero_consecutivo', ascending: false);

      final remotos = <Pedido>[];
      for (final raw in (response as List)) {
        final mapa = raw as Map<String, dynamic>;
        final pedidoId = mapa['id'] as String? ?? '';
        List<HistorialEstadoPedido>? historial;
        if (pedidoId.isNotEmpty) {
          try {
            final histRes = await _resolvedClient
                .from(_tablaHistorial)
                .select()
                .eq('pedido_id', pedidoId)
                .order('fecha', ascending: true);
            historial = (histRes as List)
                .map(
                  (h) =>
                      HistorialEstadoPedido.fromJson(h as Map<String, dynamic>),
                )
                .toList();
          } catch (_) {
            historial = null;
          }
        }
        final pedido = Pedido.fromJson(mapa, historialExterno: historial);
        remotos.add(pedido);
        if (pedido.numeroConsecutivo > _consecutivoActual) {
          _consecutivoActual = pedido.numeroConsecutivo;
        }
      }

      if (remotos.isNotEmpty) {
        for (final remoto in remotos) {
          _actualizarEnMemoria(remoto);
        }
        return remotos;
      }
    } catch (e) {
      debugPrint(
        '[SupabasePedidosRepository] Usando memoria de respaldo al consultar pedidos: $e',
      );
    }

    if (clienteEmail != null && clienteEmail.trim().isNotEmpty) {
      final norm = clienteEmail.trim().toLowerCase();
      return _memoriaPedidos
          .where((p) => p.clienteEmail.toLowerCase() == norm)
          .toList();
    }
    return List.unmodifiable(_memoriaPedidos);
  }

  @override
  Future<Pedido> confirmarPedido({
    required String clienteEmail,
    String? clienteNombre,
    required List<ItemPedido> items,
    required double subtotal,
    required double costoEnvio,
    required double total,
    String? direccionEntrega,
    String? notasCliente,
  }) async {
    if (items.isEmpty) {
      throw const CarritoVacioException();
    }

    final ahora = DateTime.now();
    final siguienteConsecutivo = _consecutivoActual + 1;
    _consecutivoActual = siguienteConsecutivo;

    final folio = Pedido.formatearFolio(siguienteConsecutivo);
    final pedidoLocalId = 'ped_${ahora.microsecondsSinceEpoch}';

    final eventoInicial = HistorialEstadoPedido(
      id: 'hp_${ahora.microsecondsSinceEpoch}',
      pedidoId: pedidoLocalId,
      estado: EstadoPedido.enEsperaPago,
      fecha: ahora,
      nota: 'Pedido confirmado por el cliente y enviado a la bandeja del taller.',
    );

    var nuevoPedido = Pedido(
      id: pedidoLocalId,
      folio: folio,
      numeroConsecutivo: siguienteConsecutivo,
      clienteEmail: clienteEmail.trim(),
      clienteNombre: clienteNombre?.trim(),
      direccionEntrega: direccionEntrega?.trim(),
      notasCliente: notasCliente?.trim(),
      estadoActual: EstadoPedido.enEsperaPago,
      items: List.unmodifiable(items),
      subtotal: subtotal,
      costoEnvio: costoEnvio,
      total: total,
      historialEstados: [eventoInicial],
      fechaCreacion: ahora,
      updatedAt: ahora,
    );

    try {
      final resPedido = await _resolvedClient
          .from(_tablaPedidos)
          .insert(nuevoPedido.toJson(includeId: false))
          .select()
          .single();

      final pedidoRemotoId = resPedido['id'] as String? ?? pedidoLocalId;
      await _resolvedClient.from(_tablaHistorial).insert({
        'pedido_id': pedidoRemotoId,
        'estado': EstadoPedido.enEsperaPago.codigo,
        'fecha': ahora.toIso8601String(),
        'nota': eventoInicial.nota,
      });

      nuevoPedido = Pedido.fromJson(
        resPedido,
        historialExterno: [
          HistorialEstadoPedido(
            id: eventoInicial.id,
            pedidoId: pedidoRemotoId,
            estado: EstadoPedido.enEsperaPago,
            fecha: ahora,
            nota: eventoInicial.nota,
          ),
        ],
      );
    } catch (e) {
      debugPrint(
        '[SupabasePedidosRepository] Pedido registrado en memoria de respaldo: $e',
      );
    }

    _memoriaPedidos.insert(0, nuevoPedido);
    return nuevoPedido;
  }

  @override
  Future<Pedido> avanzarEstadoPedido({
    required String pedidoId,
    String? nota,
  }) async {
    final idx = _memoriaPedidos.indexWhere((p) => p.id == pedidoId);
    if (idx == -1) {
      throw PedidoException('No se encontró el pedido con ID "$pedidoId".');
    }

    final actual = _memoriaPedidos[idx];
    final ahora = DateTime.now();
    final actualizado = actual.avanzarASiguienteEstado(
      fecha: ahora,
      nota: nota?.trim(),
    );

    try {
      await _resolvedClient.from(_tablaPedidos).update({
        'estado_actual': actualizado.estadoActual.codigo,
        'updated_at': ahora.toIso8601String(),
      }).eq('id', pedidoId);

      await _resolvedClient.from(_tablaHistorial).insert({
        'pedido_id': pedidoId,
        'estado': actualizado.estadoActual.codigo,
        'fecha': ahora.toIso8601String(),
        if (nota != null && nota.trim().isNotEmpty) 'nota': nota.trim(),
      });
    } catch (e) {
      debugPrint(
        '[SupabasePedidosRepository] Avance de estado actualizado en memoria local: $e',
      );
    }

    _memoriaPedidos[idx] = actualizado;
    return actualizado;
  }

  void _actualizarEnMemoria(Pedido pedido) {
    final idx = _memoriaPedidos.indexWhere((p) => p.id == pedido.id);
    if (idx != -1) {
      _memoriaPedidos[idx] = pedido;
    } else {
      _memoriaPedidos.add(pedido);
    }
    _memoriaPedidos.sort(
      (a, b) => b.numeroConsecutivo.compareTo(a.numeroConsecutivo),
    );
  }
}

