// test/features/pedidos/pedidos_viewmodel_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:barro_vivo/features/catalogo/models/pieza_catalogo.dart';
import 'package:barro_vivo/features/catalogo/repositories/catalogo_repository.dart';
import 'package:barro_vivo/features/catalogo/viewmodels/catalogo_viewmodel.dart';
import 'package:barro_vivo/features/pedidos/models/estado_pedido.dart';
import 'package:barro_vivo/features/pedidos/models/historial_estado_pedido.dart';
import 'package:barro_vivo/features/pedidos/models/item_pedido.dart';
import 'package:barro_vivo/features/pedidos/models/pedido.dart';
import 'package:barro_vivo/features/pedidos/repositories/pedidos_repository.dart';
import 'package:barro_vivo/features/pedidos/viewmodels/pedidos_viewmodel.dart';
import 'package:barro_vivo/features/produccion/models/etapa_produccion.dart';

class _FakeCatalogoRepo implements CatalogoRepository {
  _FakeCatalogoRepo(this._piezas);
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
    final actual = _piezas[idx];
    final updated = actual.copyWith(existencia: actual.existencia - cantidad);
    _piezas[idx] = updated;
    return updated;
  }
}

class _FakePedidosRepo implements PedidosRepository {
  int _consecutivo = 127;
  final List<Pedido> _pedidos = [];

  @override
  int get ultimoConsecutivo => _consecutivo;

  @override
  Future<List<Pedido>> getPedidos({String? clienteEmail}) async {
    if (clienteEmail != null && clienteEmail.isNotEmpty) {
      return _pedidos
          .where((p) => p.clienteEmail.toLowerCase() == clienteEmail.toLowerCase())
          .toList();
    }
    return List.of(_pedidos);
  }

  @override
  Future<Pedido> confirmarPedido({
    required String clienteEmail,
    String? clienteNombre,
    required List<ItemPedido> items,
    required double subtotal,
    required double costoEnvio,
    required double total,
    String? direccionEntrega,
    String? notasCliente,
  }) async {
    if (items.isEmpty) throw const CarritoVacioException();
    _consecutivo++;
    final now = DateTime.now();
    final id = 'ped_$_consecutivo';
    final pedido = Pedido(
      id: id,
      folio: Pedido.formatearFolio(_consecutivo),
      numeroConsecutivo: _consecutivo,
      clienteEmail: clienteEmail,
      clienteNombre: clienteNombre,
      direccionEntrega: direccionEntrega,
      notasCliente: notasCliente,
      estadoActual: EstadoPedido.enEsperaPago,
      items: items,
      subtotal: subtotal,
      costoEnvio: costoEnvio,
      total: total,
      fechaCreacion: now,
      historialEstados: [
        HistorialEstadoPedido(
          id: 'h_$_consecutivo',
          pedidoId: id,
          estado: EstadoPedido.enEsperaPago,
          fecha: now,
        ),
      ],
    );
    _pedidos.insert(0, pedido);
    return pedido;
  }

  @override
  Future<Pedido> avanzarEstadoPedido({
    required String pedidoId,
    String? nota,
  }) async {
    final idx = _pedidos.indexWhere((p) => p.id == pedidoId);
    final updated = _pedidos[idx].avanzarASiguienteEstado(
      fecha: DateTime.now(),
      nota: nota,
    );
    _pedidos[idx] = updated;
    return updated;
  }
}

void main() {
  late CatalogoViewModel catalogoVM;
  late PedidosViewModel pedidosVM;

  setUp(() async {
    final catalogoRepo = _FakeCatalogoRepo([
      const PiezaCatalogo(
        id: 'cat_1',
        loteId: 'l1',
        loteCodigo: 'LOTE-001',
        nombre: 'Vajilla Talavera',
        descripcion: 'Terminada.',
        categoria: 'Vajillas',
        etapaActual: EtapaProduccion.terminado,
        existencia: 3,
        precioUnitario: 1800.0,
      ),
    ]);
    catalogoVM = CatalogoViewModel(catalogoRepository: catalogoRepo);
    await catalogoVM.cargarCatalogo();
    pedidosVM = PedidosViewModel(pedidosRepository: _FakePedidosRepo());
  });

  group('HU-09 Criterio 1: Emisión de folio consecutivo y estado inicial', () {
    test('Confirma pedidos generando folios consecutivos BV-0128, BV-0129 en espera de pago y descuenta stock', () async {
      final pieza = catalogoVM.piezasPublicadas.first;
      catalogoVM.agregarAlCarrito(pieza, cantidad: 2);

      final pedido1 = await pedidosVM.confirmarPedidoDesdeCarrito(
        resumen: catalogoVM.resumenCarrito,
        clienteEmail: 'cliente@barrovivo.test',
        clienteNombre: 'Ana Sofía',
        catalogoViewModel: catalogoVM,
      );

      expect(pedido1, isNotNull);
      expect(pedido1!.folio, equals('BV-0128'));
      expect(pedido1.estadoActual, equals(EstadoPedido.enEsperaPago));
      expect(catalogoVM.carritoVacio, isTrue);
      // Queda 1 unidad disponible (3 - 2 = 1)
      expect(catalogoVM.piezasPublicadas.first.existencia, equals(1));

      // Segunda compra con la última unidad
      catalogoVM.agregarAlCarrito(catalogoVM.piezasPublicadas.first, cantidad: 1);
      final pedido2 = await pedidosVM.confirmarPedidoDesdeCarrito(
        resumen: catalogoVM.resumenCarrito,
        clienteEmail: 'cliente@barrovivo.test',
        catalogoViewModel: catalogoVM,
      );

      expect(pedido2, isNotNull);
      expect(pedido2!.folio, equals('BV-0129'));
      expect(pedido2.estadoActual, equals(EstadoPedido.enEsperaPago));
      // Al agotarse por completo, la pieza deja de publicarse
      expect(catalogoVM.piezasPublicadas, isEmpty);
    });
  });

  group('HU-09 Criterio 2: Secuencia estricta de línea de tiempo', () {
    test('Avanza estrictamente: en espera de pago -> pagado -> en preparación -> enviado -> entregado', () async {
      final pieza = catalogoVM.piezasPublicadas.first;
      catalogoVM.agregarAlCarrito(pieza, cantidad: 1);

      final pedido = await pedidosVM.confirmarPedidoDesdeCarrito(
        resumen: catalogoVM.resumenCarrito,
        clienteEmail: 'cliente@barrovivo.test',
        catalogoViewModel: catalogoVM,
      );
      expect(pedido!.estadoActual, equals(EstadoPedido.enEsperaPago));
      expect(pedido.historialEstados.length, equals(1));

      expect(await pedidosVM.avanzarEstadoPedido(pedido.id), isTrue);
      expect(pedidosVM.pedidos.first.estadoActual, equals(EstadoPedido.pagado));

      expect(await pedidosVM.avanzarEstadoPedido(pedido.id), isTrue);
      expect(
        pedidosVM.pedidos.first.estadoActual,
        equals(EstadoPedido.enPreparacion),
      );

      expect(await pedidosVM.avanzarEstadoPedido(pedido.id), isTrue);
      expect(pedidosVM.pedidos.first.estadoActual, equals(EstadoPedido.enviado));

      expect(await pedidosVM.avanzarEstadoPedido(pedido.id), isTrue);
      final finalPedido = pedidosVM.pedidos.first;
      expect(finalPedido.estadoActual, equals(EstadoPedido.entregado));
      expect(finalPedido.historialEstados.length, equals(5));
      expect(finalPedido.puedeAvanzarEstado, isFalse);

      // No puede avanzar más allá de entregado
      expect(await pedidosVM.avanzarEstadoPedido(pedido.id), isFalse);
      expect(pedidosVM.hasError, isTrue);
    });
  });
}

