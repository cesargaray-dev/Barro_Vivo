// test/features/catalogo/catalogo_viewmodel_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:barro_vivo/features/catalogo/models/pieza_catalogo.dart';
import 'package:barro_vivo/features/catalogo/models/resumen_carrito.dart';
import 'package:barro_vivo/features/catalogo/repositories/catalogo_repository.dart';
import 'package:barro_vivo/features/catalogo/viewmodels/catalogo_viewmodel.dart';
import 'package:barro_vivo/features/produccion/models/etapa_produccion.dart';

class _FakeCatalogoRepository implements CatalogoRepository {
  _FakeCatalogoRepository(this._piezas);

  final List<PiezaCatalogo> _piezas;

  @override
  Future<List<PiezaCatalogo>> getTodasLasPiezas() async => List.of(_piezas);

  @override
  Future<List<PiezaCatalogo>> getCatalogoPublicado() async =>
      _piezas.where((p) => p.esPublicableEnCatalogo).toList();

  @override
  Future<PiezaCatalogo> descontarExistencia({
    required String piezaId,
    required int cantidad,
  }) async {
    final idx = _piezas.indexWhere((p) => p.id == piezaId);
    if (idx == -1) throw const PiezaNoDisponibleException();
    final actual = _piezas[idx];
    if (actual.existencia < cantidad) {
      throw StockInsuficienteException(
        nombrePieza: actual.nombre,
        disponible: actual.existencia,
      );
    }
    final actualizada = actual.copyWith(existencia: actual.existencia - cantidad);
    _piezas[idx] = actualizada;
    return actualizada;
  }
}

void main() {
  late List<PiezaCatalogo> semilla;
  late _FakeCatalogoRepository repository;
  late CatalogoViewModel viewModel;

  setUp(() {
    semilla = [
      const PiezaCatalogo(
        id: 'p1',
        loteId: 'l1',
        loteCodigo: 'LOTE-001',
        nombre: 'Vajilla Azul Cobalto',
        descripcion: 'Vajilla terminada lista para venta.',
        categoria: 'Vajillas',
        etapaActual: EtapaProduccion.terminado,
        existencia: 5,
        precioUnitario: 1200.0,
      ),
      const PiezaCatalogo(
        id: 'p2',
        loteId: 'l2',
        loteCodigo: 'LOTE-002',
        nombre: 'Tibor Imperial',
        descripcion: 'Tibor terminado de colección.',
        categoria: 'Decoración',
        etapaActual: EtapaProduccion.terminado,
        existencia: 3,
        precioUnitario: 800.0,
      ),
      const PiezaCatalogo(
        id: 'p3',
        loteId: 'l3',
        loteCodigo: 'LOTE-003',
        nombre: 'Juego en Decorado',
        descripcion: 'Aún en proceso de pintado.',
        categoria: 'Vajillas',
        etapaActual: EtapaProduccion.decorado,
        existencia: 10,
        precioUnitario: 500.0,
      ),
      const PiezaCatalogo(
        id: 'p4',
        loteId: 'l4',
        loteCodigo: 'LOTE-004',
        nombre: 'Platón en Jahuete',
        descripcion: 'Primera quema.',
        categoria: 'Mesa y Cocina',
        etapaActual: EtapaProduccion.jahuete,
        existencia: 8,
        precioUnitario: 400.0,
      ),
      const PiezaCatalogo(
        id: 'p5',
        loteId: 'l5',
        loteCodigo: 'LOTE-005',
        nombre: 'Florero Agotado',
        descripcion: 'Terminado pero sin existencias.',
        categoria: 'Decoración',
        etapaActual: EtapaProduccion.terminado,
        existencia: 0,
        precioUnitario: 650.0,
      ),
    ];

    repository = _FakeCatalogoRepository(semilla);
    viewModel = CatalogoViewModel(catalogoRepository: repository);
  });

  group('HU-08 Criterio 1: Regla de negocio crítica del catálogo', () {
    test('Solo publica piezas en etapa terminado con existencia > 0', () async {
      await viewModel.cargarCatalogo();

      expect(viewModel.piezasPublicadas.length, equals(2));
      expect(viewModel.piezasPublicadas.map((p) => p.id), containsAll(['p1', 'p2']));
      expect(viewModel.piezasPublicadas.map((p) => p.id), isNot(contains('p3')));
      expect(viewModel.piezasPublicadas.map((p) => p.id), isNot(contains('p4')));
      expect(viewModel.piezasPublicadas.map((p) => p.id), isNot(contains('p5')));
      expect(viewModel.totalPiezasExcluidasPorRegla, equals(3));
    });

    test('Rechaza agregar al carrito piezas no terminadas o con existencia 0', () {
      final enDecorado = semilla[2];
      final agotada = semilla[4];

      expect(viewModel.agregarAlCarrito(enDecorado), isFalse);
      expect(viewModel.hasError, isTrue);
      expect(viewModel.carritoVacio, isTrue);

      expect(viewModel.agregarAlCarrito(agotada), isFalse);
      expect(viewModel.carritoVacio, isTrue);
    });

    test('Impide agregar o incrementar por encima de la existencia física', () {
      final tibor = semilla[1]; // existencia: 3

      expect(viewModel.agregarAlCarrito(tibor, cantidad: 3), isTrue);
      expect(viewModel.cantidadEnCarrito('p2'), equals(3));

      expect(viewModel.incrementarCantidad('p2'), isFalse);
      expect(viewModel.cantidadEnCarrito('p2'), equals(3));
      expect(viewModel.errorMessage, contains('existencia máxima'));
    });

    test('Al descontar toda la existencia de una pieza deja de mostrarse en el catálogo', () async {
      await viewModel.cargarCatalogo();
      final tibor = semilla[1]; // existencia: 3
      viewModel.agregarAlCarrito(tibor, cantidad: 3);

      await viewModel.aplicarDescuentoExistencias(viewModel.itemsCarrito);

      expect(viewModel.carritoVacio, isTrue);
      expect(viewModel.piezasPublicadas.map((p) => p.id), isNot(contains('p2')));
      expect(viewModel.piezasPublicadas.length, equals(1));
    });
  });

  group('HU-08 Criterio 2: Carrito y totales explícitos antes de pagar', () {
    test('Calcula partidas, total de piezas, subtotal, envío y total a pagar', () {
      final vajilla = semilla[0]; // $1,200
      final tibor = semilla[1]; // $800

      // 1 x $1,200 = $1,200 (< $1,500 => aplica envío $150 => total $1,350)
      viewModel.agregarAlCarrito(vajilla);
      ResumenCarrito resumen = viewModel.resumenCarrito;
      expect(resumen.totalPartidas, equals(1));
      expect(resumen.totalPiezas, equals(1));
      expect(resumen.subtotalProductos, equals(1200.0));
      expect(resumen.costoEnvio, equals(ResumenCarrito.costoEnvioEstandar));
      expect(resumen.totalAPagar, equals(1350.0));
      expect(resumen.tieneEnvioGratis, isFalse);

      // + 1 x $800 => subtotal $2,000 (>= $1,500 => envío gratis => total $2,000)
      viewModel.agregarAlCarrito(tibor);
      resumen = viewModel.resumenCarrito;
      expect(resumen.totalPartidas, equals(2));
      expect(resumen.totalPiezas, equals(2));
      expect(resumen.subtotalProductos, equals(2000.0));
      expect(resumen.costoEnvio, equals(0.0));
      expect(resumen.totalAPagar, equals(2000.0));
      expect(resumen.tieneEnvioGratis, isTrue);

      // Decrementar vajilla (se elimina) => queda 1 tibor ($800 + $150 = $950)
      viewModel.decrementarCantidad('p1');
      resumen = viewModel.resumenCarrito;
      expect(resumen.totalPartidas, equals(1));
      expect(resumen.subtotalProductos, equals(800.0));
      expect(resumen.costoEnvio, equals(150.0));
      expect(resumen.totalAPagar, equals(950.0));
    });
  });
}

