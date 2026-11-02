// lib/features/finanzas/viewmodels/finanzas_viewmodel.dart
//
// ViewModel para el Panel Financiero, Costo Unitario y Utilidad (HU-07).
//
// REGLA ARQUITECTÓNICA DE ORO:
//   - Este archivo importa ÚNICAMENTE [package:flutter/foundation.dart].
//   - CERO dependencias de [package:flutter/material.dart].
//   - CERO [BuildContext].
//   - Manejo de estado reactivo mediante [ChangeNotifier].

import 'package:flutter/foundation.dart';

import '../models/analisis_financiero_lote.dart';
import '../models/nivel_rentabilidad.dart';
import '../models/resumen_financiero_global.dart';
import '../repositories/finanzas_repository.dart';

/// Estados posibles del flujo de carga y mutación financiera.
enum FinanzasStatus {
  initial,
  loading,
  loaded,
  error,
}

/// Opciones de filtrado para la lista de análisis financiero de lotes.
enum FiltroFinanzas {
  todos('Todos los lotes'),
  terminados('Lotes cerrados (Terminados)'),
  enProceso('En producción activa');

  const FiltroFinanzas(this.etiqueta);
  final String etiqueta;
}

class FinanzasViewModel extends ChangeNotifier {
  FinanzasViewModel({
    required FinanzasRepository finanzasRepository,
  }) : _repository = finanzasRepository;

  final FinanzasRepository _repository;

  FinanzasStatus _status = FinanzasStatus.initial;
  String? _errorMessage;
  List<AnalisisFinancieroLote> _lotesFinancieros = [];
  AnalisisFinancieroLote? _loteSeleccionado;
  FiltroFinanzas _filtro = FiltroFinanzas.todos;

  // Estado del simulador interactivo de precios
  double? _precioSimulado;

  // ── Getters de Estado ───────────────────────────────────────────────────────

  FinanzasStatus get status => _status;
  bool get isLoading => _status == FinanzasStatus.loading;
  bool get isLoaded => _status == FinanzasStatus.loaded;
  bool get hasError => _status == FinanzasStatus.error;
  String? get errorMessage => _errorMessage;

  List<AnalisisFinancieroLote> get todosLosLotes => List.unmodifiable(_lotesFinancieros);
  AnalisisFinancieroLote? get loteSeleccionado => _loteSeleccionado;
  FiltroFinanzas get filtro => _filtro;
  double? get precioSimulado => _precioSimulado;

  // ── Métricas Consolidadas y Filtrado (HU-07) ───────────────────────────────

  /// Lista de lotes financieros filtrada según la pestaña activa.
  List<AnalisisFinancieroLote> get lotesFiltrados {
    return switch (_filtro) {
      FiltroFinanzas.todos => _lotesFinancieros,
      FiltroFinanzas.terminados =>
        _lotesFinancieros.where((l) => l.etapaActual.esUltima).toList(),
      FiltroFinanzas.enProceso =>
        _lotesFinancieros.where((l) => !l.etapaActual.esUltima).toList(),
    };
  }

  /// Resumen global del taller calculado reactivamente desde los lotes actuales.
  ResumenFinancieroGlobal get resumenGlobal =>
      ResumenFinancieroGlobal.desdeLotes(_lotesFinancieros);

  /// Costo unitario promedio ponderado por pieza útil en todo el taller (\$ MXN).
  double get costoUnitarioPromedioGlobal => resumenGlobal.costoUnitarioPromedio;

  /// Margen porcentual promedio proyectado para el taller (%).
  double get margenPromedioGlobal => resumenGlobal.margenPromedioPorcentaje;

  /// Inversión monetaria total comprometida en producción (\$ MXN).
  double get inversionTotalProduccionGlobal => resumenGlobal.inversionTotalProduccion;

  /// Ganancia bruta estimada total del taller (\$ MXN).
  double get utilidadTotalProyectadaGlobal => resumenGlobal.utilidadTotalProyectada;

  /// Total de lotes con margen riesgoso o en pérdida para atención prioritaria del dueño.
  int get cantidadLotesConMargenRiesgoso =>
      _lotesFinancieros.where((l) => l.nivelRentabilidad.esCritico).length;

  // ── Operaciones de Consulta y Mutación ──────────────────────────────────────

  /// Carga el análisis financiero de todos los lotes del taller.
  Future<void> cargarDatos() async {
    _status = FinanzasStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final lotes = await _repository.getAnalisisFinanciero();
      _lotesFinancieros = List.of(lotes);

      // Si había un lote seleccionado, actualizamos su referencia
      if (_loteSeleccionado != null) {
        _loteSeleccionado = _lotesFinancieros.cast<AnalisisFinancieroLote?>().firstWhere(
              (l) => l?.id == _loteSeleccionado!.id,
              orElse: () => null,
            );
      }

      _status = FinanzasStatus.loaded;
    } on FinanzasException catch (e) {
      _status = FinanzasStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      _status = FinanzasStatus.error;
      _errorMessage = 'Ocurrió un error inesperado al calcular las finanzas: $e';
    } finally {
      notifyListeners();
    }
  }

  /// Cambia el filtro de visualización (todos, terminados o en proceso).
  void cambiarFiltro(FiltroFinanzas nuevoFiltro) {
    if (_filtro == nuevoFiltro) return;
    _filtro = nuevoFiltro;
    notifyListeners();
  }

  /// Selecciona un lote para inspeccionar su desglose detallado en el panel.
  void seleccionarLote(String loteId) {
    try {
      _loteSeleccionado = _lotesFinancieros.firstWhere(
        (l) => l.id == loteId || l.loteId == loteId,
      );
      _precioSimulado = _loteSeleccionado?.precioVentaUnitario;
      notifyListeners();
    } catch (_) {
      _loteSeleccionado = null;
      notifyListeners();
    }
  }

  /// Limpia la selección de lote individual para volver a la vista global.
  void limpiarSeleccionLote() {
    _loteSeleccionado = null;
    _precioSimulado = null;
    notifyListeners();
  }

  // ── Simulador Interactivo de Precios (Criterio 3) ───────────────────────────

  /// Modifica el precio simulado sin persistirlo para que la UI muestre
  /// en tiempo real la proyección de utilidad y margen mientras el usuario desliza o escribe.
  void fijarPrecioSimulado(double precio) {
    _precioSimulado = precio >= 0.0 ? precio : 0.0;
    notifyListeners();
  }

  /// Calcula la utilidad unitaria estimada para un lote con un precio arbitrario.
  double calcularUtilidadSimulada(AnalisisFinancieroLote lote, double precio) {
    return precio - lote.costoUnitario;
  }

  /// Calcula el margen porcentual estimado para un lote con un precio arbitrario.
  double calcularMargenSimulado(AnalisisFinancieroLote lote, double precio) {
    if (precio <= 0.0) return 0.0;
    final utilidad = precio - lote.costoUnitario;
    return (utilidad / precio) * 100.0;
  }

  /// Evalúa el nivel de rentabilidad para un precio y costo unitario dados.
  NivelRentabilidad evaluarRentabilidadSimulada(double precio, double costoUnitario) {
    if (precio <= 0.0) return NivelRentabilidad.perdida;
    final margen = ((precio - costoUnitario) / precio) * 100.0;
    return NivelRentabilidad.evaluar(margen);
  }

  /// Persiste el nuevo precio de venta unitario acordado para el lote.
  ///
  /// Recalcula de inmediato las utilidades y actualiza las listas reactivamente.
  Future<bool> actualizarPrecioVenta({
    required String loteId,
    required double nuevoPrecio,
  }) async {
    if (nuevoPrecio < 0.0) {
      _errorMessage = 'El precio de venta debe ser un monto positivo.';
      notifyListeners();
      return false;
    }

    try {
      final actualizado = await _repository.actualizarPrecioVenta(
        loteId: loteId,
        nuevoPrecio: nuevoPrecio,
      );

      final index = _lotesFinancieros.indexWhere(
        (l) => l.id == actualizado.id || l.loteId == actualizado.loteId,
      );
      if (index != -1) {
        _lotesFinancieros[index] = actualizado;
      }

      if (_loteSeleccionado?.id == actualizado.id ||
          _loteSeleccionado?.loteId == actualizado.loteId) {
        _loteSeleccionado = actualizado;
        _precioSimulado = actualizado.precioVentaUnitario;
      }

      _errorMessage = null;
      notifyListeners();
      return true;
    } on FinanzasException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error al actualizar el precio de venta: $e';
      notifyListeners();
      return false;
    }
  }

  /// Registra un nuevo análisis o actualiza el existente y notifica.
  Future<bool> guardarAnalisis(AnalisisFinancieroLote nuevoAnalisis) async {
    try {
      final guardado = await _repository.guardarAnalisis(nuevoAnalisis);
      final index = _lotesFinancieros.indexWhere(
        (l) => l.id == guardado.id || l.loteId == guardado.loteId,
      );
      if (index != -1) {
        _lotesFinancieros[index] = guardado;
      } else {
        _lotesFinancieros.insert(0, guardado);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al guardar el análisis del lote: $e';
      notifyListeners();
      return false;
    }
  }
}
