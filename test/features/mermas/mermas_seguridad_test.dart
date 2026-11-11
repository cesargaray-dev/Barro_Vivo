// test/features/mermas/mermas_seguridad_test.dart
//
// Pruebas de seguridad de HU-06 (entradas inválidas, evidencia obligatoria y
// manejo de errores sin exponer detalles internos). Sin red ni secretos.

import 'package:flutter_test/flutter_test.dart';
import 'package:barro_vivo/features/mermas/models/insumo_consumido_merma.dart';
import 'package:barro_vivo/features/mermas/models/motivo_merma.dart';
import 'package:barro_vivo/features/mermas/models/registro_merma.dart';
import 'package:barro_vivo/features/mermas/repositories/mermas_repository.dart';
import 'package:barro_vivo/features/mermas/viewmodels/mermas_viewmodel.dart';
import 'package:barro_vivo/features/produccion/models/etapa_produccion.dart';

/// Repositorio que simula una falla del backend con un detalle interno sensible.
class _RepoQueFalla implements MermasRepository {
  static const detalleInterno = 'relation "lotes_mermas" violates RLS policy xyz';

  @override
  Future<List<RegistroMerma>> getMermas({String? loteId, bool soloActivos = true}) async =>
      throw Exception(detalleInterno);

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
  }) async =>
      throw Exception(detalleInterno);

  @override
  Future<void> darDeBajaMerma(String id) async => throw Exception(detalleInterno);
}

void main() {
  late MermasViewModel vm;

  setUp(() => vm = MermasViewModel(mermasRepository: _RepoQueFalla()));

  Future<bool> registrar({
    String loteId = 'lote-1',
    int piezas = 1,
    String evidencia = '/tmp/foto.jpg',
  }) =>
      vm.registrarMerma(
        loteId: loteId,
        loteCodigo: 'LOTE-001',
        etapa: EtapaProduccion.decorado,
        motivo: MotivoMerma.rotura,
        cantidadPiezas: piezas,
        evidenciaUrl: evidencia,
      );

  group('Entradas inválidas (validación antes de llegar al servidor)', () {
    test('rechaza merma sin evidencia fotográfica', () async {
      expect(await registrar(evidencia: '   '), isFalse);
      expect(vm.errorMessage, contains('evidencia fotográfica'));
    });

    test('rechaza cantidad de piezas cero o negativa', () async {
      expect(await registrar(piezas: 0), isFalse);
      expect(await registrar(piezas: -3), isFalse);
      expect(vm.errorMessage, contains('mayor a cero'));
    });

    test('rechaza lote vacío', () async {
      expect(await registrar(loteId: '  '), isFalse);
      expect(vm.errorMessage, contains('lote'));
    });
  });

  group('Manejo de errores sin exponer datos internos', () {
    test('un fallo del backend al registrar muestra un mensaje genérico', () async {
      expect(await registrar(), isFalse);
      expect(vm.errorMessage, isNotNull);
      expect(vm.errorMessage, isNot(contains('RLS')));
      expect(vm.errorMessage, isNot(contains('lotes_mermas')));
    });

    test('un fallo del backend al cargar muestra un mensaje genérico', () async {
      await vm.cargarMermas();
      expect(vm.hasError, isTrue);
      expect(vm.errorMessage, isNot(contains('RLS')));
      expect(vm.errorMessage, isNot(contains('lotes_mermas')));
    });

    test('un fallo del backend al dar de baja muestra un mensaje genérico', () async {
      expect(await vm.darDeBajaMerma('x'), isFalse);
      expect(vm.errorMessage, isNot(contains('RLS')));
    });

    test('la excepción de red no incluye el detalle técnico', () {
      const e = NetworkMermaException('relation "lotes_mermas" does not exist');
      expect(e.message, isNot(contains('lotes_mermas')));
    });
  });
}

