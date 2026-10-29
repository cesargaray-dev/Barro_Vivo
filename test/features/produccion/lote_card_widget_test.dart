// test/features/produccion/lote_card_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:barro_vivo/features/produccion/models/etapa_produccion.dart';
import 'package:barro_vivo/features/produccion/models/historial_etapa.dart';
import 'package:barro_vivo/features/produccion/models/lote_produccion.dart';
import 'package:barro_vivo/features/produccion/repositories/produccion_repository.dart';
import 'package:barro_vivo/features/produccion/viewmodels/produccion_viewmodel.dart';
import 'package:barro_vivo/features/produccion/views/widgets/lote_card.dart';
import 'package:barro_vivo/theme/app_theme.dart';

class _FakeProduccionRepo implements ProduccionRepository {
  @override
  Future<List<LoteProduccion>> getLotes({bool soloActivos = true}) async => [];
  @override
  Future<LoteProduccion> getLotePorId(String id) async => throw UnimplementedError();
  @override
  Future<LoteProduccion> crearLote({
    required String codigo,
    required int cantidadPiezas,
    required DateTime fechaCreacion,
    String? descripcion,
    String? notasIniciales,
  }) async => throw UnimplementedError();
  @override
  Future<LoteProduccion> avanzarEtapa({
    required String loteId,
    required DateTime fecha,
    String? notas,
  }) async => throw UnimplementedError();
  @override
  Future<List<HistorialEtapa>> getHistorialLote(String loteId) async => [];
  @override
  Future<void> darDeBajaLote(String id) async {}
}

void main() {
  testWidgets('LoteCard se renderiza correctamente sin errores de layout ni BoxConstraints', (tester) async {
    final lote = LoteProduccion(
      id: 'lote_test_1',
      codigo: 'LOTE-TEST-001',
      cantidadPiezas: 25,
      fechaCreacion: DateTime(2026, 10, 29),
      descripcion: 'Platos de talavera decorados',
      etapaActual: EtapaProduccion.barroCrudo,
      historial: [
        HistorialEtapa(
          id: 'hist_1',
          loteId: 'lote_test_1',
          etapa: EtapaProduccion.barroCrudo,
          fecha: DateTime(2026, 10, 29),
        ),
      ],
    );

    final vm = ProduccionViewModel(produccionRepository: _FakeProduccionRepo());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ChangeNotifierProvider<ProduccionViewModel>.value(
            value: vm,
            child: ListView(
              children: [
                LoteCard(lote: lote),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('LOTE-TEST-001'), findsOneWidget);
    expect(find.text('25 pzas'), findsOneWidget);
    expect(find.text('Historial'), findsOneWidget);
    expect(find.text('A Jahuete'), findsOneWidget);
  });
}
