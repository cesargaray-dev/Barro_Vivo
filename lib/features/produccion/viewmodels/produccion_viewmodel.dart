// lib/features/produccion/viewmodels/produccion_viewmodel.dart
//
// ViewModel para la gestión de lotes y avance de etapas – HU-05.
//
// Responsabilidades:
//   – Exponer el estado reactivo de producción a la UI.
//   – Manejar la creación de lotes asignando fecha.
//   – Validar y ejecutar el avance estricto de las 5 etapas.
//   – Exponer el historial consultable de transiciones con fechas.
//   – Notificar cambios con notifyListeners().

import 'package:flutter/foundation.dart';

import '../models/etapa_produccion.dart';
import '../models/historial_etapa.dart';
import '../models/lote_produccion.dart';
import '../repositories/produccion_repository.dart';

/// Estados posibles del módulo de producción.
enum ProduccionStatus {
  initial,
  loading,
  success,
  error,
}

/// ViewModel para la administración de lotes de producción en el taller.
class ProduccionViewModel extends ChangeNotifier {
  ProduccionViewModel({required ProduccionRepository produccionRepository})
      : _repository = produccionRepository;

  final ProduccionRepository _repository;

  // ── Estado interno ──────────────────────────────────────────────────────────
  ProduccionStatus _status = ProduccionStatus.initial;
  List<LoteProduccion> _lotes = [];
  String? _errorMessage;
  bool _isSaving = false;
  EtapaProduccion? _filtroEtapa;

  // ── Getters públicos de estado ──────────────────────────────────────────────
  ProduccionStatus get status => _status;
  List<LoteProduccion> get lotes => List.unmodifiable(_lotes);
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ProduccionStatus.loading;
  bool get isSaving => _isSaving;
  bool get hasError => _errorMessage != null;

  // ── Filtro por etapa ────────────────────────────────────────────────────────
  EtapaProduccion? get filtroEtapa => _filtroEtapa;

  void setFiltroEtapa(EtapaProduccion? etapa) {
    if (_filtroEtapa == etapa) {
      _filtroEtapa = null; // Deseleccionar para ver todos
    } else {
      _filtroEtapa = etapa;
    }
    notifyListeners();
  }

  /// Lista de lotes que cumplen con el filtro activo.
  List<LoteProduccion> get lotesFiltrados {
    if (_filtroEtapa == null) return lotes;
    return _lotes.where((l) => l.etapaActual == _filtroEtapa).toList();
  }

  // ── Métricas y contadores para el Dashboard ─────────────────────────────────
  int get totalLotes => _lotes.length;
  int get totalEnProceso => _lotes.where((l) => !l.estaTerminado).length;
  int get totalTerminados => _lotes.where((l) => l.estaTerminado).length;

  int conteoPorEtapa(EtapaProduccion etapa) {
    return _lotes.where((l) => l.etapaActual == etapa).length;
  }

  // ── Operaciones (Use Cases) ─────────────────────────────────────────────────

  /// Carga la lista de lotes activos desde el repositorio.
  Future<void> cargarLotes() async {
    _status = ProduccionStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _lotes = await _repository.getLotes(soloActivos: true);
      _status = ProduccionStatus.success;
    } on ProduccionException catch (e) {
      _errorMessage = e.message;
      _status = ProduccionStatus.error;
    } catch (e) {
      _errorMessage = 'Error inesperado al cargar lotes: $e';
      _status = ProduccionStatus.error;
    } finally {
      notifyListeners();
    }
  }

  /// Registra un nuevo lote de producción (Criterio 1).
  ///
  /// Inicia automáticamente en [EtapaProduccion.barroCrudo] y registra
  /// el hito inicial en el historial con la [fechaCreacion].
  Future<bool> crearLote({
    required String codigo,
    required int cantidadPiezas,
    required DateTime fechaCreacion,
    String? descripcion,
    String? notasIniciales,
  }) async {
    final codigoLimpio = codigo.trim();
    if (codigoLimpio.isEmpty) {
      _errorMessage = 'El código o nombre del lote es obligatorio.';
      notifyListeners();
      return false;
    }

    if (cantidadPiezas <= 0) {
      _errorMessage = 'La cantidad de piezas debe ser mayor a cero.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nuevoLote = await _repository.crearLote(
        codigo: codigoLimpio,
        cantidadPiezas: cantidadPiezas,
        fechaCreacion: fechaCreacion,
        descripcion: descripcion?.trim(),
        notasIniciales: notasIniciales?.trim(),
      );

      // Inserción reactiva al inicio de la lista
      _lotes = [nuevoLote, ..._lotes];
      _status = ProduccionStatus.success;
      return true;
    } on ProduccionException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Error al crear el lote: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Avanza un lote a su siguiente etapa estricta (Criterio 2 y 3).
  ///
  /// Restringe la transición a la siguiente etapa de las 5 estrictas:
  /// barro crudo -> jahuete -> esmaltado -> decorado -> terminado.
  Future<bool> avanzarEtapa({
    required String loteId,
    required DateTime fecha,
    String? notas,
  }) async {
    final index = _lotes.indexWhere((l) => l.id == loteId);
    if (index == -1) {
      _errorMessage = 'Lote no encontrado.';
      notifyListeners();
      return false;
    }

    final loteActual = _lotes[index];
    if (!loteActual.puedeAvanzar) {
      _errorMessage = 'El lote "${loteActual.codigo}" ya completó la etapa final de producción.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loteActualizado = await _repository.avanzarEtapa(
        loteId: loteId,
        fecha: fecha,
        notas: notas?.trim(),
      );

      // Actualizar reactivamente en la lista local
      final nuevaLista = List<LoteProduccion>.from(_lotes);
      nuevaLista[index] = loteActualizado;
      _lotes = nuevaLista;
      _status = ProduccionStatus.success;
      return true;
    } on TransicionEtapaInvalidaException catch (e) {
      _errorMessage = e.toString();
      return false;
    } on ProduccionException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Error al avanzar de etapa: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Consulta el historial completo de un lote.
  Future<List<HistorialEtapa>> obtenerHistorialLote(String loteId) async {
    try {
      return await _repository.getHistorialLote(loteId);
    } catch (e) {
      final lote = _lotes.firstWhere(
        (l) => l.id == loteId,
        orElse: () => throw LoteNotFoundException(loteId),
      );
      return lote.historial;
    }
  }

  /// Da de baja lógica un lote del taller.
  Future<bool> darDeBajaLote(String loteId) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.darDeBajaLote(loteId);
      _lotes = _lotes.where((l) => l.id != loteId).toList();
      _status = ProduccionStatus.success;
      return true;
    } on ProduccionException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Error al dar de baja el lote: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Limpia cualquier mensaje de error activo.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
