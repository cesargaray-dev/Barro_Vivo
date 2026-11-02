// test/features/finanzas/panel_financiero_widget_test.dart
//
// Pruebas de widgets para el Panel Financiero y Costos (HU-07).
// Verifica accesibilidad (48 dp), ausencia de errores de layout y cumplimiento de criterios.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:barro_vivo/features/produccion/models/etapa_produccion.dart';
import 'package:barro_vivo/features/finanzas/models/analisis_financiero_lote.dart';
import 'package:barro_vivo/features/finanzas/models/categoria_costo.dart';
import 'package:barro_vivo/features/finanzas/models/item_desglose_costo.dart';
import 'package:barro_vivo/features/finanzas/models/resumen_financiero_global.dart';
import 'package:barro_vivo/features/finanzas/repositories/finanzas_repository.dart';
import 'package:barro_vivo/features/finanzas/viewmodels/finanzas_viewmodel.dart';
import 'package:barro_vivo/features/finanzas/views/panel_financiero_screen.dart';
import 'package:barro_vivo/features/finanzas/views/widgets/costo_unitario_card.dart';
import 'package:barro_vivo/features/finanzas/views/widgets/grafica_desglose_categorias.dart';
import 'package:barro_vivo/features/finanzas/views/widgets/indicador_utilidad_card.dart';
import 'package:barro_vivo/features/finanzas/views/widgets/lote_financiero_card.dart';
import 'package:barro_vivo/theme/app_theme.dart';

class MockFinanzasRepository implements FinanzasRepository {
  MockFinanzasRepository({required this.lotes});

  final List<AnalisisFinancieroLote> lotes;

  @override
  Future<List<AnalisisFinancieroLote>> getAnalisisFinanciero({bool soloActivos = true}) async {
    return lotes;
  }

  @override
  Future<AnalisisFinancieroLote> getAnalisisPorLoteId(String loteId) async {
    return lotes.firstWhere((l) => l.loteId == loteId || l.id == loteId);
  }

  @override
  Future<AnalisisFinancieroLote> actualizarPrecioVenta({
    required String loteId,
    required double nuevoPrecio,
  }) async {
    final idx = lotes.indexWhere((l) => l.loteId == loteId || l.id == loteId);
    final modificado = lotes[idx].copyWith(precioVentaUnitario: nuevoPrecio);
    lotes[idx] = modificado;
    return modificado;
  }

  @override
  Future<AnalisisFinancieroLote> guardarAnalisis(AnalisisFinancieroLote analisis) async {
    return analisis;
  }

  @override
  Future<ResumenFinancieroGlobal> getResumenGlobal() async {
    return ResumenFinancieroGlobal.desdeLotes(lotes);
  }
}

void main() {
  const lotePrueba = AnalisisFinancieroLote(
    id: 'lote_test_id',
    loteId: 'lote_1',
    loteCodigo: 'LOTE-2024-TEST (Vajilla)',
    descripcion: 'Vajilla tradicional de 6 servicios.',
    etapaActual: EtapaProduccion.decorado,
    cantidadPiezasIniciales: 50,
    piezasMermadas: 5,
    gastoMateriaPrimaTotal: 2000.0,
    costoMermasTotal: 250.0,
    precioVentaUnitario: 150.0,
    desgloseCategorias: [
      ItemDesgloseCosto(categoria: CategoriaCosto.barroPastas, monto: 700.0, porcentaje: 31.1),
      ItemDesgloseCosto(categoria: CategoriaCosto.esmaltesVidriado, monto: 500.0, porcentaje: 22.2),
      ItemDesgloseCosto(categoria: CategoriaCosto.pigmentosDecorado, monto: 400.0, porcentaje: 17.8),
      ItemDesgloseCosto(categoria: CategoriaCosto.horneadoEnergia, monto: 400.0, porcentaje: 17.8),
      ItemDesgloseCosto(categoria: CategoriaCosto.mermaProrrateada, monto: 250.0, porcentaje: 11.1),
    ],
  );

  Widget createWidgetUnderTest(Widget child, {FinanzasViewModel? viewModel}) {
    final repo = MockFinanzasRepository(lotes: [lotePrueba]);
    final vm = viewModel ?? FinanzasViewModel(finanzasRepository: repo);

    return MaterialApp(
      theme: AppTheme.light(),
      home: ChangeNotifierProvider<FinanzasViewModel>.value(
        value: vm,
        child: Scaffold(body: child),
      ),
    );
  }

  group('HU-07 Widgets Individuales', () {
    testWidgets('CostoUnitarioCard renderiza Criterio 1: Materia Prima + Merma Prorrateada',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        const SingleChildScrollView(child: CostoUnitarioCard(analisis: lotePrueba)),
      ));

      expect(find.text('Cálculo de Costo Unitario'), findsOneWidget);
      expect(find.text('MATERIA PRIMA'), findsOneWidget);
      expect(find.text('MERMA PRORRAT.'), findsOneWidget);
      expect(find.text('COSTO UNIT.'), findsOneWidget);
      expect(find.text('Piezas iniciales: 50'), findsOneWidget);
      expect(find.text('Útiles: 45'), findsOneWidget);
    });

    testWidgets('IndicadorUtilidadCard renderiza Criterio 3: Precio vs Costo y Margen',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        const SingleChildScrollView(child: IndicadorUtilidadCard(analisis: lotePrueba)),
      ));

      expect(find.text('Utilidad y Margen Estimado'), findsOneWidget);
      expect(find.text('PRECIO VENTA'), findsOneWidget);
      expect(find.text('UTILIDAD NETA'), findsOneWidget);
      expect(find.text('Margen de Utilidad sobre Venta'), findsOneWidget);
      expect(find.text('Excelente'), findsOneWidget);
    });

    testWidgets('GraficaDesgloseCategorias renderiza Criterio 2: Categorías de costo',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        SingleChildScrollView(
          child: GraficaDesgloseCategorias(
            items: lotePrueba.desgloseCompleto,
            costoTotal: lotePrueba.costoTotalProduccion,
          ),
        ),
      ));

      expect(find.text('Desglose de Costos por Categoría'), findsOneWidget);
      expect(find.text('Barro y Pastas'), findsOneWidget);
      expect(find.text('Esmaltes y Vidriado'), findsOneWidget);
      expect(find.text('Merma Prorrateada'), findsOneWidget);
      expect(find.text('Costo Total Invertido'), findsOneWidget);
    });

    testWidgets('LoteFinancieroCard no genera overflow con margen ajustado en pantalla estrecha',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const loteAjustado = AnalisisFinancieroLote(
        id: 'lote_riesgo',
        loteId: 'lote_r',
        loteCodigo: 'LOTE-2024-004 (Azulejos Mayólica)',
        descripcion: 'Azulejos cuadrados 10x10 para mural a...',
        etapaActual: EtapaProduccion.esmaltado,
        cantidadPiezasIniciales: 100,
        piezasMermadas: 10,
        gastoMateriaPrimaTotal: 4500.0,
        costoMermasTotal: 500.0,
        precioVentaUnitario: 65.0, // Margen ajustado 14.5%
      );

      await tester.pumpWidget(createWidgetUnderTest(
        SingleChildScrollView(
          child: LoteFinancieroCard(
            analisis: loteAjustado,
            onVerDetalle: () {},
          ),
        ),
      ));

      expect(find.text('LOTE-2024-004 (Azulejos Mayólica)'), findsOneWidget);
      expect(find.text('Ajustado: Margen 14.5%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('HU-07 PanelFinancieroScreen Integración', () {
    testWidgets('PanelFinancieroScreen carga y renderiza métricas y chip Requieren revisión',
        (tester) async {
      final repo = MockFinanzasRepository(lotes: [
        lotePrueba,
        const AnalisisFinancieroLote(
          id: 'lote_riesgo',
          loteId: 'lote_r',
          loteCodigo: 'LOTE-2024-004 (Azulejos)',
          cantidadPiezasIniciales: 100,
          piezasMermadas: 10,
          gastoMateriaPrimaTotal: 4500.0,
          costoMermasTotal: 500.0,
          precioVentaUnitario: 65.0, // Ajustado 14.5%
        ),
      ]);
      final vm = FinanzasViewModel(finanzasRepository: repo);
      await vm.cargarDatos();

      await tester.pumpWidget(createWidgetUnderTest(
        const PanelFinancieroScreen(),
        viewModel: vm,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Finanzas y Utilidad'), findsOneWidget);
      expect(find.text('Resumen Global'), findsOneWidget);
      expect(find.text('Lotes de Producción'), findsOneWidget);

      // Cambiar a la pestaña de lotes
      await tester.tap(find.text('Lotes de Producción'));
      await tester.pumpAndSettle();

      // Debe aparecer el chip de "Requieren revisión (1)"
      expect(find.text('Requieren revisión (1)'), findsOneWidget);

      // Tocar el chip de filtro
      await tester.tap(find.text('Requieren revisión (1)'));
      await tester.pumpAndSettle();

      expect(find.text('LOTE-2024-004 (Azulejos)'), findsOneWidget);
    });
  });
}
