// test/features/catalogo/catalogo_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:barro_vivo/features/catalogo/models/pieza_catalogo.dart';
import 'package:barro_vivo/features/catalogo/repositories/catalogo_repository.dart';
import 'package:barro_vivo/features/catalogo/viewmodels/catalogo_viewmodel.dart';
import 'package:barro_vivo/features/catalogo/views/carrito_screen.dart';
import 'package:barro_vivo/features/produccion/models/etapa_produccion.dart';
import 'package:barro_vivo/models/user_model.dart';
import 'package:barro_vivo/repositories/auth_repository.dart';
import 'package:barro_vivo/viewmodels/auth_viewmodel.dart';
import 'package:barro_vivo/views/cliente/cliente_home_screen.dart';

class _FakeAuthRepo implements AuthRepository {
  @override
  Future<UserModel?> getCurrentUser() async => const UserModel(
        id: 'cli_1',
        email: 'cliente.prueba@barrovivo.com',
        role: UserRole.cliente,
        displayName: 'María Elena',
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
  @override
  Future<List<PiezaCatalogo>> getTodasLasPiezas() async => const [
        PiezaCatalogo(
          id: 'cat_1',
          loteId: 'l1',
          loteCodigo: 'LOTE-2024-001',
          nombre: 'Vajilla Clásica Terminada',
          descripcion: 'Lista para entrega inmediata.',
          categoria: 'Vajillas',
          etapaActual: EtapaProduccion.terminado,
          existencia: 4,
          precioUnitario: 1600.0,
        ),
        PiezaCatalogo(
          id: 'cat_2',
          loteId: 'l2',
          loteCodigo: 'LOTE-2024-002',
          nombre: 'Jarra Oculta En Decorado',
          descripcion: 'Aún en proceso de pintado.',
          categoria: 'Decoración',
          etapaActual: EtapaProduccion.decorado,
          existencia: 10,
          precioUnitario: 500.0,
        ),
        PiezaCatalogo(
          id: 'cat_3',
          loteId: 'l3',
          loteCodigo: 'LOTE-2024-003',
          nombre: 'Platón Oculto Sin Stock',
          descripcion: 'Terminado pero existencia 0.',
          categoria: 'Mesa y Cocina',
          etapaActual: EtapaProduccion.terminado,
          existencia: 0,
          precioUnitario: 750.0,
        ),
      ];

  @override
  Future<List<PiezaCatalogo>> getCatalogoPublicado() async {
    final todas = await getTodasLasPiezas();
    return todas.where((p) => p.esPublicableEnCatalogo).toList();
  }

  @override
  Future<PiezaCatalogo> descontarExistencia({
    required String piezaId,
    required int cantidad,
  }) =>
      throw UnimplementedError();
}

void main() {
  testWidgets(
      'HU-08: ClienteHomeScreen solo muestra piezas terminadas con existencia y permite armar carrito con totales',
      (WidgetTester tester) async {
    final authVM = AuthViewModel(authRepository: _FakeAuthRepo());
    final catalogoVM = CatalogoViewModel(catalogoRepository: _FakeCatalogoRepo());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
          ChangeNotifierProvider<CatalogoViewModel>.value(value: catalogoVM),
        ],
        child: const MaterialApp(
          home: ClienteHomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Regla crítica: visible solo la terminada con existencia > 0
    expect(find.text('Vajilla Clásica Terminada'), findsOneWidget);
    expect(find.text('Jarra Oculta En Decorado'), findsNothing);
    expect(find.text('Platón Oculto Sin Stock'), findsNothing);

    // Agregar al carrito
    await tester.tap(find.text('Agregar al carrito'));
    await tester.pumpAndSettle();

    expect(find.text('En carrito: 1'), findsOneWidget);
    expect(find.text('Ver Carrito'), findsOneWidget);

    // Abrir CarritoScreen y verificar totales explícitos
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
          ChangeNotifierProvider<CatalogoViewModel>.value(value: catalogoVM),
        ],
        child: const MaterialApp(
          home: CarritoScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Resumen de Totales'), findsOneWidget);
    expect(find.text('Total a pagar'), findsOneWidget);
    expect(find.text('\$1,600.00 MXN'), findsWidgets);
    expect(find.text('Gratis'), findsOneWidget);
  });
}

