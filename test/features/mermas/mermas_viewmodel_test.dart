// test/features/mermas/mermas_viewmodel_test.dart
//
// Pruebas unitarias de dominio y ViewModel para la Historia de Usuario HU-06:
// "Como usuario del taller, quiero registrar las mermas de un lote con su costo
// estimado, para conocer el costo real de la producción."
//
// Criterios de aceptación probados:
//   1. Se pueden registrar piezas perdidas indicando la etapa en la que ocurrió
//      el daño y el motivo (despostillado, rotura, etc.).
//   2. Es obligatorio poder adjuntar una evidencia fotográfica del daño al
//      registrar la merma.
//   3. El sistema calcula el costo estimado de la pérdida según los insumos
//      consumidos.

import 'package:flutter_test/flutter_test.dart';
import 'package:barro_vivo/features/produccion/models/etapa_produccion.dart';
import 'package:barro_vivo/features/mermas/models/insumo_consumido_merma.dart';
import 'package:barro_vivo/features/mermas/models/motivo_merma.dart';
import 'package:barro_vivo/features/mermas/models/registro_merma.dart';
import 'package:barro_vivo/features/mermas/repositories/mermas_repository.dart';
import 'package:barro_vivo/features/mermas/viewmodels/mermas_viewmodel.dart';

/// Doble de prueba (Fake) en memoria del repositorio de mermas.
class FakeMermasRepository implements MermasRepository {
  FakeMermasRepository({List<RegistroMerma>? datosIniciales})
      : _db = datosIniciales != null ? List.of(datosIniciales) : [];

  final List<RegistroMerma> _db;

  @override
  Future<List<RegistroMerma>> getMermas({
    String? loteId,
    bool soloActivos = true,
  }) async {
    Iterable<RegistroMerma> res = _db;
    if (soloActivos) {
      res = res.where((m) => m.activo);
    }
    if (loteId != null && loteId.isNotEmpty) {
      res = res.where((m) => m.loteId == loteId);
    }
    return res.toList();
  }

  @override
  Future<RegistroMerma> registrarMerma({
    required String loteId,
    required String loteCodigo,
    required EtapaProduccion etapa,
    required MotivoMerma motivo,
    required int cantidadPiezas,
    required String evidenciaUrl,
    required List<InsumoConsumidoMerma> insumosConsumidos,
    required DateTime fecha,
    String? evidenciaDescripcion,
    String? observaciones,
  }) async {
    final nueva = RegistroMerma(
      id: 'merma_${_db.length + 1}',
      loteId: loteId,
      loteCodigo: loteCodigo,
      etapa: etapa,
      motivo: motivo,
      cantidadPiezas: cantidadPiezas,
      evidenciaUrl: evidenciaUrl,
      evidenciaDescripcion: evidenciaDescripcion,
      insumosConsumidos: insumosConsumidos,
      observaciones: observaciones,
      fecha: fecha,
    );

    // Verifica reglas de negocio en dominio
    nueva.validarReglasDeNegocio();

    _db.insert(0, nueva);
    return nueva;
  }

  @override
  Future<void> darDeBajaMerma(String id) async {
    final idx = _db.indexWhere((m) => m.id == id);
    if (idx != -1) {
      _db[idx] = _db[idx].copyWith(activo: false);
    }
  }
}

void main() {
  group('HU-06 Criterio 1: Registro de piezas perdidas por etapa y motivo', () {
    late FakeMermasRepository repo;
    late MermasViewModel vm;

    setUp(() {
      repo = FakeMermasRepository();
      vm = MermasViewModel(mermasRepository: repo);
    });

    test('Permite registrar piezas perdidas indicando etapa (ej. Decorado) y motivo (Despostillado)', () async {
      final exito = await vm.registrarMerma(
        loteId: 'lote_001',
        loteCodigo: 'LOTE-2026-001',
        etapa: EtapaProduccion.decorado,
        motivo: MotivoMerma.despostillado,
        cantidadPiezas: 3,
        evidenciaUrl: 'evidencia://camara/despostillado_decorado.jpg',
        observaciones: 'Borde astillado al mover piezas pintadas.',
      );

      expect(exito, isTrue);
      expect(vm.hasError, isFalse);
      expect(vm.totalIncidentes, equals(1));
      expect(vm.totalPiezasMermadas, equals(3));

      final merma = vm.mermas.first;
      expect(merma.loteId, equals('lote_001'));
      expect(merma.etapa, equals(EtapaProduccion.decorado));
      expect(merma.motivo, equals(MotivoMerma.despostillado));
      expect(merma.cantidadPiezas, equals(3));
    });

    test('Soporta todos los motivos del taller (rotura, grieta térmica, defecto esmalte, etc.)', () async {
      for (final motivo in MotivoMerma.values) {
        final ok = await vm.registrarMerma(
          loteId: 'lote_test',
          loteCodigo: 'LOTE-MOTIVOS',
          etapa: EtapaProduccion.jahuete,
          motivo: motivo,
          cantidadPiezas: 1,
          evidenciaUrl: 'evidencia://foto_${motivo.codigo}.jpg',
        );
        expect(ok, isTrue);
      }

      expect(vm.totalIncidentes, equals(MotivoMerma.values.length));
    });

    test('Rechaza registro de merma con cantidad de piezas <= 0', () async {
      final exito = await vm.registrarMerma(
        loteId: 'lote_001',
        loteCodigo: 'LOTE-2026-001',
        etapa: EtapaProduccion.barroCrudo,
        motivo: MotivoMerma.rotura,
        cantidadPiezas: 0,
        evidenciaUrl: 'evidencia://foto.jpg',
      );

      expect(exito, isFalse);
      expect(vm.hasError, isTrue);
      expect(vm.errorMessage, contains('mayor a cero'));
      expect(vm.totalIncidentes, equals(0));
    });
  });

  group('HU-06 Criterio 2: Obligatoriedad de adjuntar evidencia fotográfica', () {
    late FakeMermasRepository repo;
    late MermasViewModel vm;

    setUp(() {
      repo = FakeMermasRepository();
      vm = MermasViewModel(mermasRepository: repo);
    });

    test('ViewModel rechaza el registro cuando la evidencia fotográfica está vacía', () async {
      final exito = await vm.registrarMerma(
        loteId: 'lote_001',
        loteCodigo: 'LOTE-2026-001',
        etapa: EtapaProduccion.jahuete,
        motivo: MotivoMerma.rotura,
        cantidadPiezas: 2,
        evidenciaUrl: '   ', // Sin evidencia fotográfica
      );

      expect(exito, isFalse);
      expect(vm.hasError, isTrue);
      expect(vm.errorMessage, contains('obligatorio adjuntar una evidencia fotográfica'));
      expect(vm.totalIncidentes, equals(0));
    });

    test('Entidad de dominio lanza EvidenciaFotograficaRequeridaException si falta la foto', () {
      final mermaSinFoto = RegistroMerma(
        id: 'm_invalida',
        loteId: 'l1',
        loteCodigo: 'LOTE-01',
        etapa: EtapaProduccion.esmaltado,
        motivo: MotivoMerma.defectoEsmalte,
        cantidadPiezas: 2,
        evidenciaUrl: '',
        insumosConsumidos: InsumoConsumidoMerma.plantillaPorEtapa(EtapaProduccion.esmaltado),
        fecha: DateTime.now(),
      );

      expect(mermaSinFoto.tieneEvidenciaFotografica, isFalse);
      expect(
        () => mermaSinFoto.validarReglasDeNegocio(),
        throwsA(isA<EvidenciaFotograficaRequeridaException>()),
      );
    });
  });

  group('HU-06 Criterio 3: Cálculo del costo estimado según insumos consumidos', () {
    test('Calcula costo exacto sumando (cantidadPorPieza * costoPorUnidad) * cantidadPiezas', () {
      // Barro: 1.5 kg * $20.00/kg = $30.00 por pieza
      // Esmalte: 0.25 lt * $80.00/lt = $20.00 por pieza
      // Gas LP: 1.0 lt * $15.00/lt = $15.00 por pieza
      // Costo unitario esperado = $65.00 por pieza
      // Para 4 piezas perdidas => Costo total estimado = $260.00 MXN
      const insumos = [
        InsumoConsumidoMerma(
          insumoId: 'i1',
          nombre: 'Barro preparado',
          unidad: 'kg',
          cantidadPorPieza: 1.5,
          costoPorUnidad: 20.0,
        ),
        InsumoConsumidoMerma(
          insumoId: 'i2',
          nombre: 'Esmalte blanco',
          unidad: 'lt',
          cantidadPorPieza: 0.25,
          costoPorUnidad: 80.0,
        ),
        InsumoConsumidoMerma(
          insumoId: 'i3',
          nombre: 'Gas LP horno',
          unidad: 'lt',
          cantidadPorPieza: 1.0,
          costoPorUnidad: 15.0,
        ),
      ];

      final merma = RegistroMerma(
        id: 'm1',
        loteId: 'l1',
        loteCodigo: 'LOTE-CALCULO',
        etapa: EtapaProduccion.esmaltado,
        motivo: MotivoMerma.rotura,
        cantidadPiezas: 4,
        evidenciaUrl: 'evidencia://foto_rotura.jpg',
        insumosConsumidos: insumos,
        fecha: DateTime(2026, 11, 8),
      );

      expect(merma.costoUnitarioEstimado, equals(65.0));
      expect(merma.costoTotalEstimado, equals(260.0));
      expect(insumos[0].cantidadTotalConsumida(4), equals(6.0)); // 6 kg de barro
      expect(insumos[0].subtotalParaPiezas(4), equals(120.0));
    });

    test('El costo acumulado por etapa crece conforme avanza el oficio artesanal', () {
      final costoBarroCrudo = RegistroMerma.calcularCostoUnitario(
        InsumoConsumidoMerma.plantillaPorEtapa(EtapaProduccion.barroCrudo),
      );
      final costoJahuete = RegistroMerma.calcularCostoUnitario(
        InsumoConsumidoMerma.plantillaPorEtapa(EtapaProduccion.jahuete),
      );
      final costoEsmaltado = RegistroMerma.calcularCostoUnitario(
        InsumoConsumidoMerma.plantillaPorEtapa(EtapaProduccion.esmaltado),
      );
      final costoDecorado = RegistroMerma.calcularCostoUnitario(
        InsumoConsumidoMerma.plantillaPorEtapa(EtapaProduccion.decorado),
      );
      final costoTerminado = RegistroMerma.calcularCostoUnitario(
        InsumoConsumidoMerma.plantillaPorEtapa(EtapaProduccion.terminado),
      );

      expect(costoBarroCrudo, greaterThan(0));
      expect(costoJahuete, greaterThan(costoBarroCrudo));
      expect(costoEsmaltado, greaterThan(costoJahuete));
      expect(costoDecorado, greaterThan(costoEsmaltado));
      expect(costoTerminado, greaterThan(costoDecorado));
    });

    test('ViewModel consolida métricas globales y filtra por etapa y motivo', () async {
      final repo = FakeMermasRepository();
      final vm = MermasViewModel(mermasRepository: repo);

      // Merma 1: 2 piezas en Barro crudo ($21.60/pza * 2 = $43.20)
      await vm.registrarMerma(
        loteId: 'lote_A',
        loteCodigo: 'LOTE-A',
        etapa: EtapaProduccion.barroCrudo,
        motivo: MotivoMerma.deformacion,
        cantidadPiezas: 2,
        evidenciaUrl: 'evidencia://foto_a.jpg',
      );

      // Merma 2: 3 piezas en Jahuete ($33.60/pza * 3 = $100.80)
      await vm.registrarMerma(
        loteId: 'lote_B',
        loteCodigo: 'LOTE-B',
        etapa: EtapaProduccion.jahuete,
        motivo: MotivoMerma.grietaTermica,
        cantidadPiezas: 3,
        evidenciaUrl: 'evidencia://foto_b.jpg',
      );

      expect(vm.totalIncidentes, equals(2));
      expect(vm.totalPiezasMermadas, equals(5));
      expect(vm.costoTotalMermasEstimado, closeTo(43.20 + 100.80, 0.01));

      // Filtrar por etapa Jahuete
      vm.setFiltroEtapa(EtapaProduccion.jahuete);
      expect(vm.mermasFiltradas.length, equals(1));
      expect(vm.mermasFiltradas.first.loteCodigo, equals('LOTE-B'));

      // Limpiar filtros y filtrar por motivo Deformación
      vm.limpiarFiltros();
      vm.setFiltroMotivo(MotivoMerma.deformacion);
      expect(vm.mermasFiltradas.length, equals(1));
      expect(vm.mermasFiltradas.first.loteCodigo, equals('LOTE-A'));
    });
  });
}

