// test/features/produccion/produccion_viewmodel_test.dart
//
// Pruebas unitarias para la Historia de Usuario HU-05:
// "Como usuario del taller, quiero registrar un lote y moverlo por las cinco etapas
// del oficio, para saber en qué punto está cada producción."

import 'package:flutter_test/flutter_test.dart';
import 'package:barro_vivo/features/produccion/models/etapa_produccion.dart';
import 'package:barro_vivo/features/produccion/models/historial_etapa.dart';
import 'package:barro_vivo/features/produccion/models/lote_produccion.dart';
import 'package:barro_vivo/features/produccion/repositories/produccion_repository.dart';
import 'package:barro_vivo/features/produccion/viewmodels/produccion_viewmodel.dart';

/// Doble de prueba (Fake) del repositorio de producción en memoria.
class _FakeProduccionRepo implements ProduccionRepository {
  final List<LoteProduccion> _db = [];

  @override
  Future<List<LoteProduccion>> getLotes({bool soloActivos = true}) async {
    return soloActivos
        ? _db.where((l) => l.activo).toList()
        : List.unmodifiable(_db);
  }

  @override
  Future<LoteProduccion> getLotePorId(String id) async {
    final index = _db.indexWhere((l) => l.id == id);
    if (index != -1) return _db[index];
    throw LoteNotFoundException(id);
  }

  @override
  Future<LoteProduccion> crearLote({
    required String codigo,
    required int cantidadPiezas,
    required DateTime fechaCreacion,
    String? descripcion,
    String? notasIniciales,
  }) async {
    final loteId = 'lote_${_db.length + 1}';
    final hitoInicial = HistorialEtapa(
      id: 'hist_0',
      loteId: loteId,
      etapa: EtapaProduccion.barroCrudo,
      fecha: fechaCreacion,
      notas: notasIniciales ?? 'Inicio en barro crudo',
      createdAt: fechaCreacion,
    );

    final nuevoLote = LoteProduccion(
      id: loteId,
      codigo: codigo,
      cantidadPiezas: cantidadPiezas,
      fechaCreacion: fechaCreacion,
      descripcion: descripcion,
      etapaActual: EtapaProduccion.barroCrudo,
      historial: [hitoInicial],
      activo: true,
      createdAt: fechaCreacion,
      updatedAt: fechaCreacion,
    );

    _db.insert(0, nuevoLote);
    return nuevoLote;
  }

  @override
  Future<LoteProduccion> avanzarEtapa({
    required String loteId,
    required DateTime fecha,
    String? notas,
  }) async {
    final index = _db.indexWhere((l) => l.id == loteId);
    if (index == -1) throw LoteNotFoundException(loteId);

    final loteActual = _db[index];
    final loteAvanzado = loteActual.avanzarASiguienteEtapa(
      fecha: fecha,
      notas: notas,
      historialId: 'hist_${loteActual.historial.length + 1}',
    );

    _db[index] = loteAvanzado;
    return loteAvanzado;
  }

  @override
  Future<List<HistorialEtapa>> getHistorialLote(String loteId) async {
    final lote = await getLotePorId(loteId);
    return lote.historial;
  }

  @override
  Future<void> darDeBajaLote(String id) async {
    final index = _db.indexWhere((l) => l.id == id);
    if (index != -1) {
      _db[index] = _db[index].copyWith(activo: false);
    }
  }
}

void main() {
  group('HU-05: Dominio y Reglas de Negocio de las 5 Etapas', () {
    test('La secuencia estricta debe ser exactamente: barro crudo -> jahuete -> esmaltado -> decorado -> terminado', () {
      expect(EtapaProduccion.barroCrudo.siguiente, EtapaProduccion.jahuete);
      expect(EtapaProduccion.jahuete.siguiente, EtapaProduccion.esmaltado);
      expect(EtapaProduccion.esmaltado.siguiente, EtapaProduccion.decorado);
      expect(EtapaProduccion.decorado.siguiente, EtapaProduccion.terminado);
      expect(EtapaProduccion.terminado.siguiente, isNull);
    });

    test('puedeTransicionarA restringe saltos no permitidos y retrocesos', () {
      // Válidos (inmediato siguiente)
      expect(EtapaProduccion.barroCrudo.puedeTransicionarA(EtapaProduccion.jahuete), isTrue);
      expect(EtapaProduccion.jahuete.puedeTransicionarA(EtapaProduccion.esmaltado), isTrue);
      expect(EtapaProduccion.esmaltado.puedeTransicionarA(EtapaProduccion.decorado), isTrue);
      expect(EtapaProduccion.decorado.puedeTransicionarA(EtapaProduccion.terminado), isTrue);

      // Inválidos: saltos hacia adelante
      expect(EtapaProduccion.barroCrudo.puedeTransicionarA(EtapaProduccion.esmaltado), isFalse);
      expect(EtapaProduccion.barroCrudo.puedeTransicionarA(EtapaProduccion.terminado), isFalse);
      expect(EtapaProduccion.jahuete.puedeTransicionarA(EtapaProduccion.decorado), isFalse);

      // Inválidos: retrocesos
      expect(EtapaProduccion.decorado.puedeTransicionarA(EtapaProduccion.jahuete), isFalse);
      expect(EtapaProduccion.terminado.puedeTransicionarA(EtapaProduccion.barroCrudo), isFalse);

      // Inválido: avanzar más allá de terminado
      expect(EtapaProduccion.terminado.puedeTransicionarA(EtapaProduccion.terminado), isFalse);
    });
  });

  group('HU-05: Criterio 1 - Crear lote y asignarle una fecha', () {
    late _FakeProduccionRepo repo;
    late ProduccionViewModel vm;

    setUp(() {
      repo = _FakeProduccionRepo();
      vm = ProduccionViewModel(produccionRepository: repo);
    });

    test('Estado inicial debe estar vacío', () {
      expect(vm.status, ProduccionStatus.initial);
      expect(vm.lotes, isEmpty);
      expect(vm.totalLotes, 0);
    });

    test('Crear lote con fecha asignada e inicializarlo en etapa Barro crudo', () async {
      final fechaAsignada = DateTime(2026, 10, 29, 10, 0);
      final exito = await vm.crearLote(
        codigo: 'LOTE-TALAVERA-001',
        cantidadPiezas: 40,
        fechaCreacion: fechaAsignada,
        descripcion: 'Jarrones con asa tradicionales',
        notasIniciales: 'Moldeado en barro negro y blanco',
      );

      expect(exito, isTrue);
      expect(vm.totalLotes, 1);
      final lote = vm.lotes.first;
      expect(lote.codigo, 'LOTE-TALAVERA-001');
      expect(lote.cantidadPiezas, 40);
      expect(lote.fechaCreacion, fechaAsignada);
      expect(lote.etapaActual, EtapaProduccion.barroCrudo);
      expect(lote.estaTerminado, isFalse);
      expect(lote.puedeAvanzar, isTrue);
      expect(lote.siguienteEtapa, EtapaProduccion.jahuete);

      // Historial contiene el hito inicial
      expect(lote.historial.length, 1);
      expect(lote.historial.first.etapa, EtapaProduccion.barroCrudo);
      expect(lote.historial.first.fecha, fechaAsignada);
    });

    test('Rechaza creación de lote con código vacío', () async {
      final exito = await vm.crearLote(
        codigo: '   ',
        cantidadPiezas: 10,
        fechaCreacion: DateTime.now(),
      );

      expect(exito, isFalse);
      expect(vm.hasError, isTrue);
      expect(vm.errorMessage, contains('código o nombre del lote es obligatorio'));
      expect(vm.totalLotes, 0);
    });

    test('Rechaza creación de lote con 0 o piezas negativas', () async {
      final exito = await vm.crearLote(
        codigo: 'LOTE-INVALIDO',
        cantidadPiezas: 0,
        fechaCreacion: DateTime.now(),
      );

      expect(exito, isFalse);
      expect(vm.hasError, isTrue);
      expect(vm.errorMessage, contains('mayor a cero'));
      expect(vm.totalLotes, 0);
    });
  });

  group('HU-05: Criterio 2 - Movimiento estricto por las cinco etapas', () {
    late _FakeProduccionRepo repo;
    late ProduccionViewModel vm;

    setUp(() async {
      repo = _FakeProduccionRepo();
      vm = ProduccionViewModel(produccionRepository: repo);

      await vm.crearLote(
        codigo: 'LOTE-FLUJO-COMPLETO',
        cantidadPiezas: 15,
        fechaCreacion: DateTime(2026, 10, 1),
      );
    });

    test('Avanza secuencialmente por las cinco etapas exactas', () async {
      final loteId = vm.lotes.first.id;

      // 1. Inicia en Barro crudo
      expect(vm.lotes.first.etapaActual, EtapaProduccion.barroCrudo);
      expect(vm.lotes.first.siguienteEtapa, EtapaProduccion.jahuete);

      // 2. Avanzar a Jahuete
      final f1 = DateTime(2026, 10, 5, 14, 0);
      final r1 = await vm.avanzarEtapa(loteId: loteId, fecha: f1, notas: 'Primera quema bizcocho');
      expect(r1, isTrue);
      expect(vm.lotes.first.etapaActual, EtapaProduccion.jahuete);
      expect(vm.lotes.first.siguienteEtapa, EtapaProduccion.esmaltado);

      // 3. Avanzar a Esmaltado
      final f2 = DateTime(2026, 10, 8, 9, 30);
      final r2 = await vm.avanzarEtapa(loteId: loteId, fecha: f2, notas: 'Inmersión en esmalte blanco');
      expect(r2, isTrue);
      expect(vm.lotes.first.etapaActual, EtapaProduccion.esmaltado);
      expect(vm.lotes.first.siguienteEtapa, EtapaProduccion.decorado);

      // 4. Avanzar a Decorado
      final f3 = DateTime(2026, 10, 15, 16, 0);
      final r3 = await vm.avanzarEtapa(loteId: loteId, fecha: f3, notas: 'Pintado con óxidos minerales');
      expect(r3, isTrue);
      expect(vm.lotes.first.etapaActual, EtapaProduccion.decorado);
      expect(vm.lotes.first.siguienteEtapa, EtapaProduccion.terminado);

      // 5. Avanzar a Terminado
      final f4 = DateTime(2026, 10, 20, 18, 0);
      final r4 = await vm.avanzarEtapa(loteId: loteId, fecha: f4, notas: 'Segunda quema 1050°C y enfriado');
      expect(r4, isTrue);
      expect(vm.lotes.first.etapaActual, EtapaProduccion.terminado);
      expect(vm.lotes.first.estaTerminado, isTrue);
      expect(vm.lotes.first.puedeAvanzar, isFalse);
      expect(vm.lotes.first.siguienteEtapa, isNull);

      // 6. Intento de avanzar más allá de Terminado debe ser rechazado
      final r5 = await vm.avanzarEtapa(loteId: loteId, fecha: DateTime(2026, 10, 25));
      expect(r5, isFalse);
      expect(vm.errorMessage, contains('ya completó la etapa final'));
    });
  });

  group('HU-05: Criterio 3 - Historial consultable de fechas de avance', () {
    late _FakeProduccionRepo repo;
    late ProduccionViewModel vm;

    setUp(() {
      repo = _FakeProduccionRepo();
      vm = ProduccionViewModel(produccionRepository: repo);
    });

    test('Conserva las fechas exactas de cada transición en el historial', () async {
      final f0 = DateTime(2026, 10, 1, 8, 0);
      await vm.crearLote(
        codigo: 'LOTE-HISTORIAL-TEST',
        cantidadPiezas: 50,
        fechaCreacion: f0,
        notasIniciales: 'Moldeado en torno',
      );

      final loteId = vm.lotes.first.id;

      final f1 = DateTime(2026, 10, 4, 12, 0);
      await vm.avanzarEtapa(loteId: loteId, fecha: f1, notas: 'Horno de bizcocho');

      final f2 = DateTime(2026, 10, 7, 10, 0);
      await vm.avanzarEtapa(loteId: loteId, fecha: f2, notas: 'Baño blanco');

      final f3 = DateTime(2026, 10, 12, 17, 30);
      await vm.avanzarEtapa(loteId: loteId, fecha: f3, notas: 'Decorado plumeado');

      final f4 = DateTime(2026, 10, 18, 19, 0);
      await vm.avanzarEtapa(loteId: loteId, fecha: f4, notas: 'Salida de horno final');

      // Consultar historial
      final historial = await vm.obtenerHistorialLote(loteId);
      expect(historial.length, 5);

      // Verificar orden y fechas
      expect(historial[0].etapa, EtapaProduccion.barroCrudo);
      expect(historial[0].fecha, f0);
      expect(historial[0].notas, 'Moldeado en torno');

      expect(historial[1].etapa, EtapaProduccion.jahuete);
      expect(historial[1].fecha, f1);
      expect(historial[1].notas, 'Horno de bizcocho');

      expect(historial[2].etapa, EtapaProduccion.esmaltado);
      expect(historial[2].fecha, f2);

      expect(historial[3].etapa, EtapaProduccion.decorado);
      expect(historial[3].fecha, f3);

      expect(historial[4].etapa, EtapaProduccion.terminado);
      expect(historial[4].fecha, f4);

      // Método auxiliar de consulta de fecha por etapa
      final loteActual = vm.lotes.first;
      expect(loteActual.fechaDeEtapa(EtapaProduccion.jahuete), f1);
      expect(loteActual.fechaDeEtapa(EtapaProduccion.terminado), f4);
    });
  });

  group('HU-05: Filtros y Métricas en ViewModel', () {
    late _FakeProduccionRepo repo;
    late ProduccionViewModel vm;

    setUp(() async {
      repo = _FakeProduccionRepo();
      vm = ProduccionViewModel(produccionRepository: repo);

      // Lote 1: Barro crudo
      await vm.crearLote(codigo: 'LOTE-A', cantidadPiezas: 10, fechaCreacion: DateTime.now());

      // Lote 2: Avanzar hasta Jahuete
      await vm.crearLote(codigo: 'LOTE-B', cantidadPiezas: 20, fechaCreacion: DateTime.now());
      await vm.avanzarEtapa(loteId: vm.lotes.first.id, fecha: DateTime.now());

      // Lote 3: Avanzar hasta Terminado
      await vm.crearLote(codigo: 'LOTE-C', cantidadPiezas: 30, fechaCreacion: DateTime.now());
      final idC = vm.lotes.first.id;
      await vm.avanzarEtapa(loteId: idC, fecha: DateTime.now()); // Jahuete
      await vm.avanzarEtapa(loteId: idC, fecha: DateTime.now()); // Esmaltado
      await vm.avanzarEtapa(loteId: idC, fecha: DateTime.now()); // Decorado
      await vm.avanzarEtapa(loteId: idC, fecha: DateTime.now()); // Terminado
    });

    test('Métricas de lotes en proceso y terminados son correctas', () {
      expect(vm.totalLotes, 3);
      expect(vm.totalEnProceso, 2);
      expect(vm.totalTerminados, 1);
      expect(vm.conteoPorEtapa(EtapaProduccion.barroCrudo), 1);
      expect(vm.conteoPorEtapa(EtapaProduccion.jahuete), 1);
      expect(vm.conteoPorEtapa(EtapaProduccion.terminado), 1);
    });

    test('Filtrar por etapa actual actualiza lotesFiltrados reactivamente', () {
      expect(vm.lotesFiltrados.length, 3);

      vm.setFiltroEtapa(EtapaProduccion.jahuete);
      expect(vm.lotesFiltrados.length, 1);
      expect(vm.lotesFiltrados.first.codigo, 'LOTE-B');

      vm.setFiltroEtapa(EtapaProduccion.terminado);
      expect(vm.lotesFiltrados.length, 1);
      expect(vm.lotesFiltrados.first.codigo, 'LOTE-C');

      // Quitar filtro
      vm.setFiltroEtapa(EtapaProduccion.terminado);
      expect(vm.filtroEtapa, isNull);
      expect(vm.lotesFiltrados.length, 3);
    });
  });
}
