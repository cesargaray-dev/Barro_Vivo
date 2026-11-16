// lib/main.dart
//
// ══════════════════════════════════════════════════════════════════════════════
// COMPOSITION ROOT – Barro Vivo (HU-01 / HU-03 / HU-05)
// ══════════════════════════════════════════════════════════════════════════════
//
// Responsabilidades de este archivo:
//   1. Inicializar Supabase antes de levantar la UI.
//   2. Construir el árbol de dependencias (MultiProvider) inyectando:
//      – Repositorios concretos (implementaciones de las interfaces).
//      – ViewModels que reciben los repositorios por constructor.
//   3. Arrancar la app con MaterialApp.router usando GoRouter y el tema global.
//
// Flujo: View → ViewModel → Repository → Model
// Ningún widget conoce Supabase directamente.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'features/catalogo/repositories/catalogo_repository.dart';
import 'features/catalogo/viewmodels/catalogo_viewmodel.dart';
import 'features/inventario/repositories/insumos_repository.dart';
import 'features/inventario/viewmodels/inventario_viewmodel.dart';
import 'features/produccion/repositories/produccion_repository.dart';
import 'features/produccion/viewmodels/produccion_viewmodel.dart';
import 'features/mermas/repositories/mermas_repository.dart';
import 'features/mermas/viewmodels/mermas_viewmodel.dart';
import 'features/finanzas/repositories/finanzas_repository.dart';
import 'features/finanzas/viewmodels/finanzas_viewmodel.dart';
import 'repositories/auth_repository.dart';
import 'router/app_router.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'viewmodels/auth_viewmodel.dart';

Future<void> main() async {
  // Garantiza que los bindings de Flutter estén listos antes de
  // ejecutar código asíncrono (p. ej. inicialización de Supabase).
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Inicializar Supabase (Singleton) ────────────────────────────────
  // En producción las credenciales vendrán de variables de entorno.
  await SupabaseService.initialize();

  // ── 2. Construir las dependencias de la capa de datos ──────────────────
  // Los repositorios concretos se crean aquí y se inyectan hacia arriba.
  final AuthRepository authRepository = SupabaseAuthRepository();
  final InsumosRepository insumosRepository = SupabaseInsumosRepository();
  final ProduccionRepository produccionRepository = SupabaseProduccionRepository();
  final MermasRepository mermasRepository = SupabaseMermasRepository();
  final FinanzasRepository finanzasRepository = SupabaseFinanzasRepository();
  final CatalogoRepository catalogoRepository = SupabaseCatalogoRepository();

  // ── 3. Levantar la aplicación ──────────────────────────────────────────
  runApp(
    BarroVivoApp(
      authRepository: authRepository,
      insumosRepository: insumosRepository,
      produccionRepository: produccionRepository,
      mermasRepository: mermasRepository,
      finanzasRepository: finanzasRepository,
      catalogoRepository: catalogoRepository,
    ),
  );
}

/// Raíz de la aplicación Barro Vivo.
///
/// Configura el [MultiProvider] global con todos los ViewModels
/// y arranca la UI mediante [MaterialApp.router].
class BarroVivoApp extends StatefulWidget {
  const BarroVivoApp({
    super.key,
    required this.authRepository,
    this.insumosRepository,
    this.produccionRepository,
    this.mermasRepository,
    this.finanzasRepository,
    this.catalogoRepository,
  });

  /// Repositorio de autenticación inyectado desde [main].
  final AuthRepository authRepository;

  /// Repositorio de insumos inyectado desde [main] o pruebas.
  final InsumosRepository? insumosRepository;

  /// Repositorio de producción de lotes inyectado desde [main] o pruebas.
  final ProduccionRepository? produccionRepository;

  /// Repositorio de registro de mermas inyectado desde [main] o pruebas (HU-06).
  final MermasRepository? mermasRepository;

  /// Repositorio financiero inyectado desde [main] o pruebas.
  final FinanzasRepository? finanzasRepository;

  /// Repositorio comercial de catálogo inyectado desde [main] o pruebas (HU-08).
  final CatalogoRepository? catalogoRepository;

  @override
  State<BarroVivoApp> createState() => _BarroVivoAppState();
}

class _BarroVivoAppState extends State<BarroVivoApp> {
  // Los ViewModels se crean aquí para que el GoRouter y widgets puedan
  // escucharlos y recalcular estados/redirecciones reactivamente.
  late final AuthViewModel _authViewModel;
  late final InventarioViewModel _inventarioViewModel;
  late final ProduccionViewModel _produccionViewModel;
  late final MermasViewModel _mermasViewModel;
  late final FinanzasViewModel _finanzasViewModel;
  late final CatalogoViewModel _catalogoViewModel;

  @override
  void initState() {
    super.initState();
    _authViewModel = AuthViewModel(authRepository: widget.authRepository);
    _inventarioViewModel = InventarioViewModel(
      insumosRepository: widget.insumosRepository ?? SupabaseInsumosRepository(),
    );
    _produccionViewModel = ProduccionViewModel(
      produccionRepository: widget.produccionRepository ?? SupabaseProduccionRepository(),
    );
    _mermasViewModel = MermasViewModel(
      mermasRepository: widget.mermasRepository ?? SupabaseMermasRepository(),
    );
    _finanzasViewModel = FinanzasViewModel(
      finanzasRepository: widget.finanzasRepository ?? SupabaseFinanzasRepository(),
    );
    _catalogoViewModel = CatalogoViewModel(
      catalogoRepository: widget.catalogoRepository ?? SupabaseCatalogoRepository(),
    );
  }

  @override
  void dispose() {
    _authViewModel.dispose();
    _inventarioViewModel.dispose();
    _produccionViewModel.dispose();
    _mermasViewModel.dispose();
    _finanzasViewModel.dispose();
    _catalogoViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // ── Árbol de dependencias (Composition Root) ─────────────────────────
      // Orden: primero los repositorios, luego los ViewModels que los usan.
      providers: [
        // ── Capa de Repositorios ──────────────────────────────────────────
        Provider<AuthRepository>.value(value: widget.authRepository),
        Provider<InsumosRepository>.value(
          value: widget.insumosRepository ?? SupabaseInsumosRepository(),
        ),
        Provider<ProduccionRepository>.value(
          value: widget.produccionRepository ?? SupabaseProduccionRepository(),
        ),
        Provider<MermasRepository>.value(
          value: widget.mermasRepository ?? SupabaseMermasRepository(),
        ),
        Provider<FinanzasRepository>.value(
          value: widget.finanzasRepository ?? SupabaseFinanzasRepository(),
        ),
        Provider<CatalogoRepository>.value(
          value: widget.catalogoRepository ?? SupabaseCatalogoRepository(),
        ),

        // ── Capa de ViewModels ────────────────────────────────────────────
        // Se usa ChangeNotifierProvider para que los widgets puedan
        // suscribirse y reconstruirse cuando el estado cambia.
        ChangeNotifierProvider<AuthViewModel>.value(value: _authViewModel),
        ChangeNotifierProvider<InventarioViewModel>.value(
          value: _inventarioViewModel,
        ),
        ChangeNotifierProvider<ProduccionViewModel>.value(
          value: _produccionViewModel,
        ),
        ChangeNotifierProvider<MermasViewModel>.value(
          value: _mermasViewModel,
        ),
        ChangeNotifierProvider<FinanzasViewModel>.value(
          value: _finanzasViewModel,
        ),
        ChangeNotifierProvider<CatalogoViewModel>.value(
          value: _catalogoViewModel,
        ),
      ],
      child: _AppRouter(authViewModel: _authViewModel),
    );
  }
}

/// Widget interno que construye el [GoRouter] y el [MaterialApp.router].
///
/// Se separa en su propio widget para que [AppRouter.create] reciba
/// el [AuthViewModel] ya inicializado (evita el problema de
/// "context used before initialization").
class _AppRouter extends StatefulWidget {
  const _AppRouter({required this.authViewModel});

  final AuthViewModel authViewModel;

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.create(widget.authViewModel);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // ── Metadatos de la app ─────────────────────────────────────────────
      title: 'Barro Vivo',
      debugShowCheckedModeBanner: false,

      // ── Tema global (Material Design 3) ─────────────────────────────────
      theme: AppTheme.light(),

      // ── Navegación (Navigator 2.0 via GoRouter) ──────────────────────────
      routerConfig: _router,
    );
  }
}
