// test/features/finanzas/finanzas_viewmodel_test.dart
//
// Pruebas unitarias de dominio y ViewModel para HU-07:
// "Como dueño del taller, quiero ver el costo unitario y la utilidad de mi producción, para decidir precios con datos reales."

import 'package:flutter_test/flutter_test.dart';
import 'package:barro_vivo/features/produccion/models/etapa_produccion.dart';
import 'package:barro_vivo/features/finanzas/models/analisis_financiero_lote.dart';
import 'package:barro_vivo/features/finanzas/models/categoria_costo.dart';
import 'package:barro_vivo/features/finanzas/models/nivel_rentabilidad.dart';
import 'package:barro_vivo/features/finanzas/models/resumen_financiero_global.dart';
import 'package:barro_vivo/features/finanzas/repositories/finanzas_repository.dart';
import 'package:barro_vivo/features/finanzas/viewmodels/finanzas_viewmodel.dart';

/// Doble de prueba en memoria para aislar la lógica de negocio sin backend.
class FakeFinanzasRepository implements FinanzasRepository {
  FakeFinanzasRepository({List<AnalisisFinancieroLote>? datosIniciales})
      : _datos = datosIniciales != null ? List.of(datosIniciales) : [];

  final List<AnalisisFinancieroLote> _datos;

  @override
  Future<List<AnalisisFinancieroLote>> getAnalisisFinanciero({bool soloActivos = true}) async {
    return List.unmodifiable(_datos);
  }

  @override
  Future<AnalisisFinancieroLote> getAnalisisPorLoteId(String loteId) async {
    return _datos.firstWhere(
      (a) => a.loteId == loteId || a.id == loteId,
      orElse: () => throw AnalisisNotFoundException(loteId),
    );
  }

  @override
  Future<AnalisisFinancieroLote> actualizarPrecioVenta({
    required String loteId,
    required double nuevoPrecio,
  }) async {
    final idx = _datos.indexWhere((a) => a.loteId == loteId || a.id == loteId);
    if (idx == -1) throw AnalisisNotFoundException(loteId);

    final actualizado = _datos[idx].copyWith(precioVentaUnitario: nuevoPrecio);
    _datos[idx] = actualizado;
    return actualizado;
  }

  @override
  Future<AnalisisFinancieroLote> guardarAnalisis(AnalisisFinancieroLote analisis) async {
    final idx = _datos.indexWhere((a) => a.id == analisis.id || a.loteId == analisis.loteId);
    if (idx != -1) {
      _datos[idx] = analisis;
    } else {
      _datos.add(analisis);
    }
    return analisis;
  }

  @override
  Future<ResumenFinancieroGlobal> getResumenGlobal() async {
    return ResumenFinancieroGlobal.desdeLotes(_datos);
  }
}

void main() {
  group('HU-07 Criterio 1: Cálculo de Costo Unitario con Merma Prorrateada', () {
    test('Calcula costo unitario sumando gasto MP unitario + merma prorrateada', () {
      // 50 piezas iniciales, 10 mermas => 40 piezas útiles
      // Gasto MP total: $2,000.00 => $50.00 por pieza útil
      // Pérdida por merma: $400.00 => $10.00 prorrateado por pieza útil
      // Costo Unitario esperado: $50.00 + $10.00 = $60.00 por pieza
      const lote = AnalisisFinancieroLote(
        id: 'test_1',
        loteId: 'lote_1',
        loteCodigo: 'LOTE-TEST-001',
        cantidadPiezasIniciales: 50,
        piezasMermadas: 10,
        gastoMateriaPrimaTotal: 2000.0,
        costoMermasTotal: 400.0,
        precioVentaUnitario: 100.0,
      );

      expect(lote.piezasUtiles, equals(40));
      expect(lote.gastoMateriaPrimaUnitario, equals(50.0));
      expect(lote.mermaProrrateadaUnitaria, equals(10.0));
      expect(lote.costoUnitario, equals(60.0));
      expect(lote.costoTotalProduccion, equals(2400.0));
    });

    test('Lote sin mermas divide el gasto directamente entre todas las piezas', () {
      const lote = AnalisisFinancieroLote(
        id: 'test_2',
        loteId: 'lote_2',
        loteCodigo: 'LOTE-PERFECTO',
        cantidadPiezasIniciales: 25,
        piezasMermadas: 0,
        gastoMateriaPrimaTotal: 1500.0,
        costoMermasTotal: 0.0,
        precioVentaUnitario: 120.0,
      );

      expect(lote.piezasUtiles, equals(25));
      expect(lote.gastoMateriaPrimaUnitario, equals(60.0));
      expect(lote.mermaProrrateadaUnitaria, equals(0.0));
      expect(lote.costoUnitario, equals(60.0));
      expect(lote.tieneMermas, isFalse);
    });

    test('Maneja con seguridad el caso extremo de 100% de mermas sin división por cero', () {
      const lote = AnalisisFinancieroLote(
        id: 'test_fail',
        loteId: 'lote_fail',
        loteCodigo: 'LOTE-TOTAL-MERMADO',
        cantidadPiezasIniciales: 10,
        piezasMermadas: 10, // 0 útiles
        gastoMateriaPrimaTotal: 1000.0,
        costoMermasTotal: 1000.0,
        precioVentaUnitario: 200.0,
      );

      expect(lote.piezasUtiles, equals(0));
      // No lanza excepción de división por cero
      expect(lote.costoUnitario, isNotNull);
      expect(lote.costoUnitario, greaterThan(0));
    });
  });

  group('HU-07 Criterio 2: Desglose por Categoría y Resumen Financiero', () {
    test('Genera desglose estructurado con porcentajes normalizados que suman 100%', () {
      const lote = AnalisisFinancieroLote(
        id: 'test_3',
        loteId: 'lote_3',
        loteCodigo: 'LOTE-DESGLOSE',
        cantidadPiezasIniciales: 50,
        piezasMermadas: 5,
        gastoMateriaPrimaTotal: 2000.0,
        costoMermasTotal: 500.0,
        precioVentaUnitario: 150.0,
      );

      final desglose = lote.desgloseCompleto;
      expect(desglose, isNotEmpty);

      // Debe incluir la categoría de merma prorrateada
      final tieneMermaCat = desglose.any((c) => c.categoria == CategoriaCosto.mermaProrrateada);
      expect(tieneMermaCat, isTrue);

      // La suma de porcentajes debe aproximarse al 100%
      final sumaPorcentajes = desglose.fold<double>(0.0, (acc, item) => acc + item.porcentaje);
      expect(sumaPorcentajes, closeTo(100.0, 0.1));
    });

    test('Resumen global consolida totales correctamente desde múltiples lotes', () {
      final lotes = [
        const AnalisisFinancieroLote(
          id: '1',
          loteId: 'l1',
          loteCodigo: 'L1',
          cantidadPiezasIniciales: 50,
          piezasMermadas: 5,
          gastoMateriaPrimaTotal: 2000.0,
          costoMermasTotal: 300.0,
          precioVentaUnitario: 100.0,
        ),
        const AnalisisFinancieroLote(
          id: '2',
          loteId: 'l2',
          loteCodigo: 'L2',
          cantidadPiezasIniciales: 30,
          piezasMermadas: 2,
          gastoMateriaPrimaTotal: 1500.0,
          costoMermasTotal: 200.0,
          precioVentaUnitario: 120.0,
        ),
      ];

      final global = ResumenFinancieroGlobal.desdeLotes(lotes);

      expect(global.totalLotes, equals(2));
      expect(global.totalPiezasIniciales, equals(80));
      expect(global.totalPiezasMermadas, equals(7));
      expect(global.totalPiezasUtiles, equals(73));
      expect(global.gastoMateriaPrimaGlobal, equals(3500.0));
      expect(global.costoMermasGlobal, equals(500.0));
      expect(global.inversionTotalProduccion, equals(4000.0));
      expect(global.costoUnitarioPromedio, closeTo(4000.0 / 73, 0.01));
    });
  });

  group('HU-07 Criterio 3: Indicador de Utilidad y Margen vs Precio de Venta', () {
    test('Calcula utilidad neta y clasifica rentabilidad en Excelente (>= 45%)', () {
      // Costo unitario = (1000 + 200) / 20 = $60.00
      // Precio venta = $150.00
      // Utilidad = $90.00
      // Margen = (90 / 150) * 100 = 60.0% => Excelente
      const lote = AnalisisFinancieroLote(
        id: 'test_rentable',
        loteId: 'lote_r',
        loteCodigo: 'LOTE-EXCELENTE',
        cantidadPiezasIniciales: 25,
        piezasMermadas: 5,
        gastoMateriaPrimaTotal: 1000.0,
        costoMermasTotal: 200.0,
        precioVentaUnitario: 150.0,
      );

      expect(lote.costoUnitario, equals(60.0));
      expect(lote.utilidadUnitaria, equals(90.0));
      expect(lote.margenUtilidadPorcentaje, equals(60.0));
      expect(lote.nivelRentabilidad, equals(NivelRentabilidad.excelente));
      expect(lote.nivelRentabilidad.esRentable, isTrue);
      expect(lote.nivelRentabilidad.esCritico, isFalse);
    });

    test('Clasifica rentabilidad en Saludable (25% a 44%)', () {
      // Costo unitario = $60.00, Precio venta = $90.00
      // Utilidad = $30.00, Margen = 33.33%
      const lote = AnalisisFinancieroLote(
        id: 'test_saludable',
        loteId: 'lote_s',
        loteCodigo: 'LOTE-SALUDABLE',
        cantidadPiezasIniciales: 20,
        piezasMermadas: 0,
        gastoMateriaPrimaTotal: 1200.0,
        costoMermasTotal: 0.0,
        precioVentaUnitario: 90.0,
      );

      expect(lote.costoUnitario, equals(60.0));
      expect(lote.margenUtilidadPorcentaje, closeTo(33.33, 0.01));
      expect(lote.nivelRentabilidad, equals(NivelRentabilidad.saludable));
    });

    test('Detecta margen ajustado o en riesgo (1% a 24%)', () {
      // Costo unitario = $60.00, Precio venta = $68.00
      // Utilidad = $8.00, Margen = 11.76%
      const lote = AnalisisFinancieroLote(
        id: 'test_ajustado',
        loteId: 'lote_a',
        loteCodigo: 'LOTE-AJUSTADO',
        cantidadPiezasIniciales: 20,
        piezasMermadas: 0,
        gastoMateriaPrimaTotal: 1200.0,
        costoMermasTotal: 0.0,
        precioVentaUnitario: 68.0,
      );

      expect(lote.nivelRentabilidad, equals(NivelRentabilidad.ajustado));
      expect(lote.nivelRentabilidad.esCritico, isTrue);
    });

    test('Detecta venta en pérdida cuando precio < costo unitario', () {
      // Costo unitario = $60.00, Precio venta = $50.00
      // Utilidad = -$10.00, Margen = -20%
      const lote = AnalisisFinancieroLote(
        id: 'test_perdida',
        loteId: 'lote_p',
        loteCodigo: 'LOTE-PERDIDA',
        cantidadPiezasIniciales: 20,
        piezasMermadas: 0,
        gastoMateriaPrimaTotal: 1200.0,
        costoMermasTotal: 0.0,
        precioVentaUnitario: 50.0,
      );

      expect(lote.utilidadUnitaria, equals(-10.0));
      expect(lote.margenUtilidadPorcentaje, lessThan(0.0));
      expect(lote.nivelRentabilidad, equals(NivelRentabilidad.perdida));
      expect(lote.nivelRentabilidad.esCritico, isTrue);
    });
  });

  group('FinanzasViewModel Tests Reactivos', () {
    late FakeFinanzasRepository repository;
    late FinanzasViewModel viewModel;

    setUp(() {
      repository = FakeFinanzasRepository(datosIniciales: [
        const AnalisisFinancieroLote(
          id: 'f1',
          loteId: 'l1',
          loteCodigo: 'Lote Terminado',
          etapaActual: EtapaProduccion.terminado,
          cantidadPiezasIniciales: 50,
          piezasMermadas: 5,
          gastoMateriaPrimaTotal: 2000.0,
          costoMermasTotal: 250.0,
          precioVentaUnitario: 120.0,
        ),
        const AnalisisFinancieroLote(
          id: 'f2',
          loteId: 'l2',
          loteCodigo: 'Lote en Jahuete',
          etapaActual: EtapaProduccion.jahuete,
          cantidadPiezasIniciales: 30,
          piezasMermadas: 3,
          gastoMateriaPrimaTotal: 1200.0,
          costoMermasTotal: 150.0,
          precioVentaUnitario: 90.0,
        ),
      ]);
      viewModel = FinanzasViewModel(finanzasRepository: repository);
    });

    test('Estado inicial es initial y luego de cargar pasa a loaded', () async {
      expect(viewModel.status, equals(FinanzasStatus.initial));
      await viewModel.cargarDatos();
      expect(viewModel.status, equals(FinanzasStatus.loaded));
      expect(viewModel.todosLosLotes.length, equals(2));
    });

    test('Filtrado por pestañas responde correctamente', () async {
      await viewModel.cargarDatos();

      // Todos
      viewModel.cambiarFiltro(FiltroFinanzas.todos);
      expect(viewModel.lotesFiltrados.length, equals(2));

      // Terminados (Lote cerrado)
      viewModel.cambiarFiltro(FiltroFinanzas.terminados);
      expect(viewModel.lotesFiltrados.length, equals(1));
      expect(viewModel.lotesFiltrados.first.loteCodigo, equals('Lote Terminado'));

      // En proceso
      viewModel.cambiarFiltro(FiltroFinanzas.enProceso);
      expect(viewModel.lotesFiltrados.length, equals(1));
      expect(viewModel.lotesFiltrados.first.loteCodigo, equals('Lote en Jahuete'));
    });

    test('Simulador interactivo recalcula utilidad y margen al vuelo sin persistir', () async {
      await viewModel.cargarDatos();
      final lote = viewModel.todosLosLotes.first; // Costo unitario = $50.00 ($2250 / 45)

      viewModel.fijarPrecioSimulado(160.0);
      expect(viewModel.precioSimulado, equals(160.0));

      final utilidadSimulada = viewModel.calcularUtilidadSimulada(lote, 160.0);
      final margenSimulado = viewModel.calcularMargenSimulado(lote, 160.0);

      expect(utilidadSimulada, equals(110.0)); // 160 - 50 = 110
      expect(margenSimulado, closeTo((110.0 / 160.0) * 100, 0.01));
    });

    test('Actualizar precio de venta persiste y actualiza reactivamente', () async {
      await viewModel.cargarDatos();

      final exito = await viewModel.actualizarPrecioVenta(
        loteId: 'l1',
        nuevoPrecio: 175.0,
      );

      expect(exito, isTrue);
      final actualizado = viewModel.todosLosLotes.firstWhere((l) => l.loteId == 'l1');
      expect(actualizado.precioVentaUnitario, equals(175.0));
      expect(actualizado.utilidadUnitaria, equals(125.0)); // 175 - 50 = 125
    });

    test('Rechaza precios negativos con mensaje de error', () async {
      await viewModel.cargarDatos();

      final exito = await viewModel.actualizarPrecioVenta(
        loteId: 'l1',
        nuevoPrecio: -20.0,
      );

      expect(exito, isFalse);
      expect(viewModel.errorMessage, isNotNull);
    });
  });
}
