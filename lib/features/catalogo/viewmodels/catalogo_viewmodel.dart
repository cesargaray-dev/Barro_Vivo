// lib/features/catalogo/viewmodels/catalogo_viewmodel.dart
//
// ViewModel para el Catálogo de Piezas y Carrito del Cliente (HU-08).
//
// REGLA ARQUITECTÓNICA DE ORO:
//   - Este archivo importa ÚNICAMENTE [package:flutter/foundation.dart].
//   - CERO dependencias de [package:flutter/material.dart].
//   - CERO [BuildContext].

import 'package:flutter/foundation.dart';

import '../models/item_carrito.dart';
import '../models/pieza_catalogo.dart';
import '../models/resumen_carrito.dart';
import '../repositories/catalogo_repository.dart';

/// Estados posibles de carga del catálogo comercial.
enum CatalogoStatus {
  initial,
  loading,
  loaded,
  error,
}

/// ViewModel reactivo que administra el catálogo publicado y el carrito del cliente.
class CatalogoViewModel extends ChangeNotifier {
  CatalogoViewModel({
    required CatalogoRepository catalogoRepository,
  }) : _repository = catalogoRepository;

  final CatalogoRepository _repository;

  CatalogoStatus _status = CatalogoStatus.initial;
  List<PiezaCatalogo> _todasLasPiezas = [];
  final Map<String, ItemCarrito> _carrito = {};
  String? _categoriaSeleccionada;
  String _busqueda = '';
  String? _errorMessage;

  // ── Getters de Estado ───────────────────────────────────────────────────────

  CatalogoStatus get status => _status;
  bool get isLoading => _status == CatalogoStatus.loading;
  bool get isLoaded => _status == CatalogoStatus.loaded;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;

  String? get categoriaSeleccionada => _categoriaSeleccionada;
  String get busqueda => _busqueda;

  /// Catálogo publicado visible al cliente.
  ///
  /// Regla de negocio crítica (HU-08 Criterio 1):
  /// Solo expone piezas que hayan alcanzado la etapa "terminado" y que
  /// tengan existencia mayor a cero.
  List<PiezaCatalogo> get piezasPublicadas =>
      _todasLasPiezas.where((p) => p.esPublicableEnCatalogo).toList();

  /// Cantidad de piezas ocultadas por no estar terminadas o estar agotadas.
  int get totalPiezasExcluidasPorRegla =>
      _todasLasPiezas.where((p) => !p.esPublicableEnCatalogo).length;

  /// Categorías únicas disponibles dentro del catálogo publicado.
  List<String> get categoriasDisponibles {
    final categorias = piezasPublicadas.map((p) => p.categoria).toSet().toList();
    categorias.sort();
    return categorias;
  }

  /// Lista reactiva filtrada por categoría y texto de búsqueda.
  List<PiezaCatalogo> get piezasFiltradas {
    final query = _busqueda.trim().toLowerCase();
    return piezasPublicadas.where((pieza) {
      if (_categoriaSeleccionada != null &&
          pieza.categoria != _categoriaSeleccionada) {
        return false;
      }
      if (query.isNotEmpty) {
        final coincideNombre = pieza.nombre.toLowerCase().contains(query);
        final coincideDesc = pieza.descripcion.toLowerCase().contains(query);
        final coincideLote = pieza.loteCodigo.toLowerCase().contains(query);
        if (!coincideNombre && !coincideDesc && !coincideLote) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // ── Getters de Carrito (HU-08 Criterio 2) ───────────────────────────────────

  List<ItemCarrito> get itemsCarrito => List.unmodifiable(_carrito.values);

  /// Resumen explícito del carrito (partidas, piezas, subtotal, envío, total).
  ResumenCarrito get resumenCarrito => ResumenCarrito(items: itemsCarrito);

  int get cantidadTotalEnCarrito => resumenCarrito.totalPiezas;

  double get totalCarrito => resumenCarrito.totalAPagar;

  bool get carritoVacio => _carrito.isEmpty;

  int cantidadEnCarrito(String piezaId) => _carrito[piezaId]?.cantidad ?? 0;

  // ── Acciones de Catálogo ────────────────────────────────────────────────────

  /// Carga el inventario comercial aplicando el filtro de piezas terminadas con stock.
  Future<void> cargarCatalogo() async {
    _status = CatalogoStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final piezas = await _repository.getTodasLasPiezas();
      _todasLasPiezas = List.of(piezas);
      _status = CatalogoStatus.loaded;
    } on CatalogoException catch (e) {
      _errorMessage = e.message;
      _status = CatalogoStatus.error;
    } catch (e) {
      debugPrint('[catalogo_viewmodel] Error al cargar el catálogo: $e');
      _errorMessage = 'No se pudo cargar el catálogo. Intenta de nuevo.';
      _status = CatalogoStatus.error;
    } finally {
      notifyListeners();
    }
  }

  void seleccionarCategoria(String? categoria) {
    _categoriaSeleccionada = categoria;
    notifyListeners();
  }

  void actualizarBusqueda(String texto) {
    _busqueda = texto;
    notifyListeners();
  }

  void limpiarError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Acciones de Carrito ─────────────────────────────────────────────────────

  /// Añade [cantidad] unidades de [pieza] al carrito validando la regla de
  /// negocio crítica (etapa terminado y existencia disponible).
  bool agregarAlCarrito(PiezaCatalogo pieza, {int cantidad = 1}) {
    if (!pieza.esPublicableEnCatalogo) {
      _errorMessage =
          'Solo se pueden adquirir piezas terminadas con existencia disponible.';
      notifyListeners();
      return false;
    }

    if (cantidad <= 0) {
      _errorMessage = 'La cantidad debe ser mayor a cero.';
      notifyListeners();
      return false;
    }

    final cantidadActual = cantidadEnCarrito(pieza.id);
    final nuevaCantidad = cantidadActual + cantidad;

    if (nuevaCantidad > pieza.existencia) {
      _errorMessage =
          'Stock insuficiente: solo hay ${pieza.existencia} unidades disponibles de "${pieza.nombre}".';
      notifyListeners();
      return false;
    }

    _carrito[pieza.id] = ItemCarrito(pieza: pieza, cantidad: nuevaCantidad);
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  /// Incrementa en 1 la cantidad de un artículo ya agregado al carrito.
  bool incrementarCantidad(String piezaId) {
    final actual = _carrito[piezaId];
    if (actual == null) return false;

    if (actual.cantidad + 1 > actual.pieza.existencia) {
      _errorMessage =
          'Alcanzaste la existencia máxima disponible (${actual.pieza.existencia} pzas).';
      notifyListeners();
      return false;
    }

    _carrito[piezaId] = actual.copyWith(cantidad: actual.cantidad + 1);
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  /// Decrementa en 1 la cantidad de un artículo; si llega a 0 lo elimina.
  bool decrementarCantidad(String piezaId) {
    final actual = _carrito[piezaId];
    if (actual == null) return false;

    if (actual.cantidad <= 1) {
      _carrito.remove(piezaId);
    } else {
      _carrito[piezaId] = actual.copyWith(cantidad: actual.cantidad - 1);
    }
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  /// Establece manualmente una [nuevaCantidad] para [piezaId].
  bool cambiarCantidad(String piezaId, int nuevaCantidad) {
    final actual = _carrito[piezaId];
    if (actual == null) return false;

    if (nuevaCantidad <= 0) {
      _carrito.remove(piezaId);
      _errorMessage = null;
      notifyListeners();
      return true;
    }

    if (nuevaCantidad > actual.pieza.existencia) {
      _errorMessage =
          'Stock insuficiente: solo hay ${actual.pieza.existencia} unidades disponibles.';
      notifyListeners();
      return false;
    }

    _carrito[piezaId] = actual.copyWith(cantidad: nuevaCantidad);
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  void eliminarDelCarrito(String piezaId) {
    _carrito.remove(piezaId);
    _errorMessage = null;
    notifyListeners();
  }

  void vaciarCarrito() {
    _carrito.clear();
    _errorMessage = null;
    notifyListeners();
  }

  /// Descuenta existencias en el repositorio tras confirmar un pedido y vacía el carrito.
  Future<void> aplicarDescuentoExistencias(List<ItemCarrito> itemsComprados) async {
    for (final item in itemsComprados) {
      try {
        final actualizada = await _repository.descontarExistencia(
          piezaId: item.pieza.id,
          cantidad: item.cantidad,
        );
        final idx = _todasLasPiezas.indexWhere((p) => p.id == actualizada.id);
        if (idx != -1) {
          _todasLasPiezas[idx] = actualizada;
        }
      } catch (e) {
        debugPrint(
          '[catalogo_viewmodel] Advertencia al descontar existencia de ${item.pieza.id}: $e',
        );
      }
    }
    _carrito.clear();
    _errorMessage = null;
    notifyListeners();
  }
}

