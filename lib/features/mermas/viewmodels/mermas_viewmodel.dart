// lib/features/mermas/viewmodels/mermas_viewmodel.dart
//
// ViewModel para el Registro de Mermas con Costo Estimado (HU-06).
//
// REGLA ARQUITECTÓNICA DE ORO:
//   - Este archivo importa ÚNICAMENTE [package:flutter/foundation.dart].
//   - CERO dependencias de [package:flutter/material.dart].
//   - CERO [BuildContext].
//   - Manejo de estado reactivo mediante [ChangeNotifier].

import 'package:flutter/foundation.dart';

import '../../produccion/models/etapa_produccion.dart';
import '../models/insumo_consumido_merma.dart';
import '../models/motivo_merma.dart';
import '../models/registro_merma.dart';
import '../repositories/mermas_repository.dart';

/// Estados posibles del flujo de carga y registro de mermas.
enum MermasStatus {
  initial,
  loading,
  loaded,
  error,
}

/// ViewModel que administra el registro de mermas, su evidencia fotográfica
/// obligatoria y el cálculo del costo estimado por insumos consumidos.
class MermasViewModel extends ChangeNotifier {
  MermasViewModel({
    required MermasRepository mermasRepository,
  }) : _repository = mermasRepository;

  final MermasRepository _repository;

  // ── Estado Interno ──────────────────────────────────────────────────────────
  MermasStatus _status = MermasStatus.initial;
  List<RegistroMerma> _mermas = [];
  String? _errorMessage;
  bool _isSaving = false;

  EtapaProduccion? _filtroEtapa;
  MotivoMerma? _filtroMotivo;
  String? _filtroLoteId;

  // ── Getters de Estado ───────────────────────────────────────────────────────
  MermasStatus get status => _status;
  bool get isLoading => _status == MermasStatus.loading;
  bool get isLoaded => _status == MermasStatus.loaded;
  bool get isSaving => _isSaving;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;

  List<RegistroMerma> get mermas => List.unmodifiable(_mermas);
  EtapaProduccion? get filtroEtapa => _filtroEtapa;
  MotivoMerma? get filtroMotivo => _filtroMotivo;
  String? get filtroLoteId => _filtroLoteId;

  // ── Lista Filtrada Reactiva ─────────────────────────────────────────────────

  /// Lista de mermas que cumplen con los filtros activos de etapa, motivo y lote.
  List<RegistroMerma> get mermasFiltradas {
    return _mermas.where((m) {
      if (_filtroEtapa != null && m.etapa != _filtroEtapa) return false;
      if (_filtroMotivo != null && m.motivo != _filtroMotivo) return false;
      if (_filtroLoteId != null &&
          _filtroLoteId!.isNotEmpty &&
          m.loteId != _filtroLoteId) {
        return false;
      }
      return true;
    }).toList();
  }

  // ── Métricas Consolidadas del Taller (HU-06) ────────────────────────────────

  /// Total de incidentes de merma registrados en el taller.
  int get totalIncidentes => _mermas.length;

  /// Total acumulado de piezas perdidas en todos los lotes.
  int get totalPiezasMermadas =>
      _mermas.fold<int>(0, (acc, m) => acc + m.cantidadPiezas);

  /// Costo económico total estimado de las pérdidas por merma ($ MXN).
  double get costoTotalMermasEstimado =>
      _mermas.fold<double>(0.0, (acc, m) => acc + m.costoTotalEstimado);

  /// Costo promedio estimado por cada pieza perdida ($ MXN).
  double get costoPromedioPorPiezaMermada {
    final piezas = totalPiezasMermadas;
    if (piezas <= 0) return 0.0;
    return costoTotalMermasEstimado / piezas;
  }

  /// Cantidad de incidentes registrados en una [etapa] específica.
  int conteoPorEtapa(EtapaProduccion etapa) {
    return _mermas.where((m) => m.etapa == etapa).length;
  }

  /// Cantidad de piezas perdidas en una [etapa] específica.
  int piezasPerdidasPorEtapa(EtapaProduccion etapa) {
    return _mermas
        .where((m) => m.etapa == etapa)
        .fold<int>(0, (acc, m) => acc + m.cantidadPiezas);
  }

  /// Cantidad de incidentes por un [motivo] específico.
  int conteoPorMotivo(MotivoMerma motivo) {
    return _mermas.where((m) => m.motivo == motivo).length;
  }

  /// Obtiene todas las mermas asociadas a un lote específico ([loteId] o [loteCodigo]).
  List<RegistroMerma> mermasDeLote(String loteId, {String? loteCodigo}) {
    return _mermas.where((m) {
      if (m.loteId == loteId) return true;
      if (loteCodigo != null &&
          loteCodigo.isNotEmpty &&
          m.loteCodigo.toLowerCase().contains(loteCodigo.toLowerCase())) {
        return true;
      }
      return false;
    }).toList();
  }

  /// Total de piezas perdidas acumuladas para un lote específico.
  int piezasMermadasDeLote(String loteId, {String? loteCodigo}) {
    return mermasDeLote(loteId, loteCodigo: loteCodigo)
        .fold<int>(0, (acc, m) => acc + m.cantidadPiezas);
  }

  /// Costo total estimado de mermas acumuladas para un lote específico ($ MXN).
  double costoMermasDeLote(String loteId, {String? loteCodigo}) {
    return mermasDeLote(loteId, loteCodigo: loteCodigo)
        .fold<double>(0.0, (acc, m) => acc + m.costoTotalEstimado);
  }

  // ── Cálculos de Costo Estimado según Insumos Consumidos (Criterio 3) ────────

  /// Devuelve la lista predeterminada de insumos consumidos acumulados hasta [etapa].
  List<InsumoConsumidoMerma> obtenerInsumosSugeridosPorEtapa(EtapaProduccion etapa) {
    return InsumoConsumidoMerma.plantillaPorEtapa(etapa);
  }

  /// Calcula el costo unitario estimado por pieza dañada según los [insumos] consumidos.
  double calcularCostoUnitarioEstimado(List<InsumoConsumidoMerma> insumos) {
    return RegistroMerma.calcularCostoUnitario(insumos);
  }

  /// Calcula el costo total estimado de la pérdida para [cantidadPiezas] según [insumos].
  double calcularCostoTotalEstimado({
    required int cantidadPiezas,
    required List<InsumoConsumidoMerma> insumos,
  }) {
    return RegistroMerma.calcularCostoTotal(
      cantidadPiezas: cantidadPiezas,
      insumos: insumos,
    );
  }

  // ── Gestión de Filtros ──────────────────────────────────────────────────────

  void setFiltroEtapa(EtapaProduccion? etapa) {
    if (_filtroEtapa == etapa) {
      _filtroEtapa = null;
    } else {
      _filtroEtapa = etapa;
    }
    notifyListeners();
  }

  void setFiltroMotivo(MotivoMerma? motivo) {
    if (_filtroMotivo == motivo) {
      _filtroMotivo = null;
    } else {
      _filtroMotivo = motivo;
    }
    notifyListeners();
  }

  void setFiltroLoteId(String? loteId) {
    _filtroLoteId = (loteId != null && loteId.trim().isNotEmpty) ? loteId.trim() : null;
    notifyListeners();
  }

  void limpiarFiltros() {
    _filtroEtapa = null;
    _filtroMotivo = null;
    _filtroLoteId = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Casos de Uso (Operaciones Asíncronas) ───────────────────────────────────

  /// Carga la lista de mermas registradas en el taller.
  Future<void> cargarMermas({String? loteId}) async {
    _status = MermasStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultado = await _repository.getMermas(
        loteId: loteId,
        soloActivos: true,
      );
      _mermas = List.of(resultado);
      _status = MermasStatus.loaded;
    } on MermaException catch (e) {
      _errorMessage = e.message;
      _status = MermasStatus.error;
    } catch (e) {
      _errorMessage = 'Error inesperado al cargar el registro de mermas: $e';
      _status = MermasStatus.error;
    } finally {
      notifyListeners();
    }
  }

  /// Registra una nueva merma cumpliendo los 3 criterios de aceptación de HU-06:
  ///   1. Indica lote, cantidad de piezas perdidas, etapa y motivo del daño.
  ///   2. Valida que sea obligatorio adjuntar evidencia fotográfica ([evidenciaUrl]).
  ///   3. Calcula el costo estimado según los [insumosConsumidos].
  Future<bool> registrarMerma({
    required String loteId,
    required String loteCodigo,
    required EtapaProduccion etapa,
    required MotivoMerma motivo,
    required int cantidadPiezas,
    required String evidenciaUrl,
    List<InsumoConsumidoMerma>? insumosConsumidos,
    DateTime? fecha,
    String? evidenciaDescripcion,
    String? observaciones,
  }) async {
    // Validación 1: Lote y cantidad de piezas (Criterio 1)
    if (loteId.trim().isEmpty || loteCodigo.trim().isEmpty) {
      _errorMessage = 'Debe seleccionar un lote de producción válido.';
      notifyListeners();
      return false;
    }

    if (cantidadPiezas <= 0) {
      _errorMessage = 'La cantidad de piezas perdidas debe ser mayor a cero.';
      notifyListeners();
      return false;
    }

    // Validación 2: Evidencia fotográfica obligatoria (Criterio 2)
    if (evidenciaUrl.trim().isEmpty) {
      _errorMessage =
          'Es obligatorio adjuntar una evidencia fotográfica del daño al registrar la merma.';
      notifyListeners();
      return false;
    }

    // Validación 3: Insumos consumidos y cálculo de costo estimado (Criterio 3)
    final listaInsumos = (insumosConsumidos != null && insumosConsumidos.isNotEmpty)
        ? insumosConsumidos
        : InsumoConsumidoMerma.plantillaPorEtapa(etapa);

    final costoUnitario = calcularCostoUnitarioEstimado(listaInsumos);
    if (costoUnitario <= 0.0) {
      _errorMessage =
          'El costo estimado según los insumos consumidos debe ser mayor a cero.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nuevaMerma = await _repository.registrarMerma(
        loteId: loteId.trim(),
        loteCodigo: loteCodigo.trim(),
        etapa: etapa,
        motivo: motivo,
        cantidadPiezas: cantidadPiezas,
        evidenciaUrl: evidenciaUrl.trim(),
        evidenciaDescripcion: evidenciaDescripcion?.trim(),
        insumosConsumidos: listaInsumos,
        fecha: fecha ?? DateTime.now(),
        observaciones: observaciones?.trim(),
      );

      _mermas = [nuevaMerma, ..._mermas];
      _status = MermasStatus.loaded;
      return true;
    } on EvidenciaFotograficaRequeridaException catch (e) {
      _errorMessage = e.message;
      return false;
    } on CantidadMermaInvalidaException catch (e) {
      _errorMessage = e.message;
      return false;
    } on InsumosMermaVaciosException catch (e) {
      _errorMessage = e.message;
      return false;
    } on MermaException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Error al registrar la merma: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Da de baja lógica un registro de merma.
  Future<bool> darDeBajaMerma(String id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.darDeBajaMerma(id);
      _mermas = _mermas.where((m) => m.id != id).toList();
      _status = MermasStatus.loaded;
      return true;
    } on MermaException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Error al eliminar el registro de merma: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}

