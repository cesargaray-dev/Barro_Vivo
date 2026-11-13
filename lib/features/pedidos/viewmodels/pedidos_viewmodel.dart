// lib/features/pedidos/viewmodels/pedidos_viewmodel.dart
//
// ViewModel para la Confirmación de Pedidos, Bandeja del Taller y Línea de Tiempo (HU-09).
//
// REGLA ARQUITECTÓNICA DE ORO:
//   - Este archivo importa ÚNICAMENTE [package:flutter/foundation.dart].
//   - CERO dependencias de [package:flutter/material.dart].
//   - CERO [BuildContext].

import 'package:flutter/foundation.dart';

import '../../catalogo/models/resumen_carrito.dart';
import '../../catalogo/viewmodels/catalogo_viewmodel.dart';
import '../models/estado_pedido.dart';
import '../models/item_pedido.dart';
import '../models/pedido.dart';
import '../repositories/pedidos_repository.dart';

/// Estados de carga de pedidos.
enum PedidosStatus {
  initial,
  loading,
  loaded,
  error,
}

/// ViewModel reactivo que coordina confirmación de compras, bandeja de pedidos
/// del cliente ("Mis pedidos"), bandeja del taller y línea de tiempo de estados.
class PedidosViewModel extends ChangeNotifier {
  PedidosViewModel({
    required PedidosRepository pedidosRepository,
  }) : _repository = pedidosRepository;

  final PedidosRepository _repository;

  PedidosStatus _status = PedidosStatus.initial;
  List<Pedido> _pedidos = [];
  Pedido? _ultimoPedidoConfirmado;
  EstadoPedido? _filtroEstado;
  bool _isProcessing = false;
  String? _errorMessage;

  // ── Getters de Estado ───────────────────────────────────────────────────────

  PedidosStatus get status => _status;
  bool get isLoading => _status == PedidosStatus.loading;
  bool get isLoaded => _status == PedidosStatus.loaded;
  bool get isProcessing => _isProcessing;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;

  List<Pedido> get pedidos => List.unmodifiable(_pedidos);
  Pedido? get ultimoPedidoConfirmado => _ultimoPedidoConfirmado;
  EstadoPedido? get filtroEstado => _filtroEstado;

  /// Lista de pedidos filtrada por [_filtroEstado] si hay uno activo.
  List<Pedido> get pedidosFiltrados {
    if (_filtroEstado == null) return List.unmodifiable(_pedidos);
    return _pedidos.where((p) => p.estadoActual == _filtroEstado).toList();
  }

  // ── Métricas para la Bandeja del Taller y Cliente ───────────────────────────

  int get totalPedidos => _pedidos.length;

  int get totalEnEsperaPago =>
      _pedidos.where((p) => p.estadoActual == EstadoPedido.enEsperaPago).length;

  int get totalEnCurso =>
      _pedidos.where((p) => p.estadoActual != EstadoPedido.entregado).length;

  int get totalEntregados =>
      _pedidos.where((p) => p.estadoActual == EstadoPedido.entregado).length;

  // ── Casos de Uso ────────────────────────────────────────────────────────────

  /// Carga los pedidos del cliente indicado o todos los pedidos para el taller.
  Future<void> cargarPedidos({String? clienteEmail}) async {
    _status = PedidosStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultado = await _repository.getPedidos(clienteEmail: clienteEmail);
      _pedidos = List.of(resultado);
      _status = PedidosStatus.loaded;
    } on PedidoException catch (e) {
      _errorMessage = e.message;
      _status = PedidosStatus.error;
    } catch (e) {
      debugPrint('[pedidos_viewmodel] Error al cargar pedidos: $e');
      _errorMessage = 'No se pudieron cargar los pedidos. Intenta de nuevo.';
      _status = PedidosStatus.error;
    } finally {
      notifyListeners();
    }
  }

  /// Confirma la compra desde [resumen], emite folio consecutivo `BV-XXXX`,
  /// asigna estado inicial `En espera de pago`, descuenta existencias del
  /// catálogo y limpia el carrito.
  Future<Pedido?> confirmarPedidoDesdeCarrito({
    required ResumenCarrito resumen,
    required String clienteEmail,
    String? clienteNombre,
    String? direccionEntrega,
    String? notasCliente,
    CatalogoViewModel? catalogoViewModel,
  }) async {
    if (resumen.estaVacio) {
      _errorMessage =
          'Agrega al menos una pieza al carrito antes de confirmar el pedido.';
      notifyListeners();
      return null;
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final itemsPedido = resumen.items
          .map(
            (i) => ItemPedido(
              piezaId: i.pieza.id,
              loteCodigo: i.pieza.loteCodigo,
              nombrePieza: i.pieza.nombre,
              cantidad: i.cantidad,
              precioUnitario: i.precioUnitario,
            ),
          )
          .toList();

      final nuevoPedido = await _repository.confirmarPedido(
        clienteEmail: clienteEmail,
        clienteNombre: clienteNombre,
        items: itemsPedido,
        subtotal: resumen.subtotalProductos,
        costoEnvio: resumen.costoEnvio,
        total: resumen.totalAPagar,
        direccionEntrega: direccionEntrega,
        notasCliente: notasCliente,
      );

      if (catalogoViewModel != null) {
        await catalogoViewModel.aplicarDescuentoExistencias(resumen.items);
      }

      _pedidos = [nuevoPedido, ..._pedidos];
      _ultimoPedidoConfirmado = nuevoPedido;
      _status = PedidosStatus.loaded;
      return nuevoPedido;
    } on PedidoException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      debugPrint('[pedidos_viewmodel] Error al confirmar pedido: $e');
      _errorMessage = 'Ocurrió un error al confirmar tu pedido. Intenta de nuevo.';
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Avanza el pedido indicado al siguiente estado de la línea de tiempo.
  Future<bool> avanzarEstadoPedido(String pedidoId, {String? nota}) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final actualizado = await _repository.avanzarEstadoPedido(
        pedidoId: pedidoId,
        nota: nota,
      );
      _pedidos = _pedidos
          .map((p) => p.id == actualizado.id ? actualizado : p)
          .toList();
      if (_ultimoPedidoConfirmado?.id == actualizado.id) {
        _ultimoPedidoConfirmado = actualizado;
      }
      _status = PedidosStatus.loaded;
      return true;
    } on PedidoException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      debugPrint('[pedidos_viewmodel] Error al avanzar estado del pedido: $e');
      _errorMessage = 'No se pudo actualizar el estado del pedido.';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void seleccionarFiltroEstado(EstadoPedido? estado) {
    _filtroEstado = estado;
    notifyListeners();
  }

  void limpiarUltimoPedidoConfirmado() {
    _ultimoPedidoConfirmado = null;
    notifyListeners();
  }

  void limpiarError() {
    _errorMessage = null;
    notifyListeners();
  }
}

