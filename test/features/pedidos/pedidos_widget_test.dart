// test/features/pedidos/pedidos_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:barro_vivo/features/catalogo/models/pieza_catalogo.dart';
import 'package:barro_vivo/features/catalogo/repositories/catalogo_repository.dart';
import 'package:barro_vivo/features/catalogo/viewmodels/catalogo_viewmodel.dart';
import 'package:barro_vivo/features/catalogo/views/carrito_screen.dart';
import 'package:barro_vivo/features/pedidos/repositories/pedidos_repository.dart';
import 'package:barro_vivo/features/pedidos/viewmodels/pedidos_viewmodel.dart';
import 'package:barro_vivo/features/pedidos/views/mis_pedidos_screen.dart';
import 'package:barro_vivo/features/produccion/models/etapa_produccion.dart';
import 'package:barro_vivo/models/user_model.dart';
import 'package:barro_vivo/repositories/auth_repository.dart';
import 'package:barro_vivo/viewmodels/auth_viewmodel.dart';

class _FakeAuthRepo implements AuthRepository {
  @override
  Future<UserModel?> getCurrentUser() async => const UserModel(
        id: 'cli_1',
        email: 'cliente@barrovivo.test',
        role: UserRole.cliente,
        displayName: 'Ana Sofía',
      );

  @override
  Future<UserModel> signIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required UserRole role,
    String? displayName,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

class _FakeCatalogoRepo implements CatalogoRepository {
  final List<PiezaCatalogo> _piezas = [
    const PiezaCatalogo(
      id: 'cat_1',
      loteId: 'l1',
      loteCodigo: 'LOTE-2024-001',
      nombre: 'Vajilla Clásica 6 Servicios',
      descripcion: 'Vajilla terminada lista para venta.',
      categoria: 'Vajillas',
      etapaActual: EtapaProduccion.terminado,
      existencia: 5,
      precioUnitario: 1850.0,
    ),
  ];

  @override
  Future<List<PiezaCatalogo>> getTodasLasPiezas() async => List.of(_piezas);

  @override
  Future<List<PiezaCatalogo>> getCatalogoPublicado() async => List.of(_piezas);

  @override
  Future<PiezaCatalogo> descontarExistencia({
    required String piezaId,
    required int cantidad,
  }) async {
    final idx = _piezas.indexWhere((p) => p.id == piezaId);
    final updated = _piezas[idx].copyWith(
      existencia: _piezas[idx].existencia - cantidad,
    );
    _piezas[idx] = updated;
    return updated;
  }
}

void main() {
  testWidgets(
      'HU-09: Confirmar pedido emite folio BV-0128 y MisPedidosScreen muestra la línea de tiempo completa',
      (WidgetTester tester) async {
    final authVM = AuthViewModel(authRepository: _FakeAuthRepo());
    final catalogoVM = CatalogoViewModel(catalogoRepository: _FakeCatalogoRepo());
    final pedidosVM = PedidosViewModel(
      pedidosRepository: SupabasePedidosRepository(),
    );

    await catalogoVM.cargarCatalogo();
    catalogoVM.agregarAlCarrito(catalogoVM.piezasPublicadas.first, cantidad: 1);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
          ChangeNotifierProvider<CatalogoViewModel>.value(value: catalogoVM),
          ChangeNotifierProvider<PedidosViewModel>.value(value: pedidosVM),
        ],
        child: const MaterialApp(
          home: CarritoScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Confirmar el pedido desde el carrito
    await tester.scrollUntilVisible(
      find.text('Confirmar pedido'),
      200,
    );
    await tester.tap(find.text('Confirmar pedido'));
    await tester.pumpAndSettle();

    // Se muestra el diálogo con el folio consecutivo BV-0128 y estado inicial
    expect(find.text('Pedido Confirmado'), findsOneWidget);
    expect(find.text('BV-0128'), findsOneWidget);
    expect(find.text('Estado inicial: En espera de pago'), findsOneWidget);

    // Ahora renderizar la bandeja "Mis pedidos" y comprobar la línea de tiempo
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
          ChangeNotifierProvider<CatalogoViewModel>.value(value: catalogoVM),
          ChangeNotifierProvider<PedidosViewModel>.value(value: pedidosVM),
        ],
        child: const MaterialApp(
          home: MisPedidosScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Mis pedidos'), findsOneWidget);
    expect(find.text('Folio BV-0128'), findsOneWidget);
    expect(find.text('En espera de pago'), findsWidgets);
    expect(find.text('Pagado'), findsWidgets);
    expect(find.text('En preparación'), findsWidgets);
    expect(find.text('Enviado'), findsWidgets);
    expect(find.text('Entregado'), findsWidgets);
  });
}

