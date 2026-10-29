// lib/router/app_router.dart
//
// Configuración central de navegación con go_router (Navigator 2.0) – HU-02 / HU-05.
//
// Rutas:
//   /               → SplashScreen  (evaluación de sesión)
//   /login          → LoginScreen
//   /registro       → RegistroScreen
//   /taller         → TallerHomeScreen  [requiere rol: taller]
//   /taller/inventario → InventarioScreen
//   /taller/lotes   → LotesScreen [HU-05]
//   /cliente        → ClienteHomeScreen [requiere rol: cliente]
//
// Guards (redirección automática):
//   – Sin sesión      → redirige a /login
//   – Rol 'taller'    → redirige a /taller
//   – Rol 'cliente'   → redirige a /cliente
//   – En login/reg. autenticado → redirige según rol

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/inventario/views/inventario_screen.dart';
import '../features/produccion/views/lotes_screen.dart';
import '../models/user_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../views/splash_screen.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/registro_screen.dart';
import '../views/taller/taller_home_screen.dart';
import '../views/cliente/cliente_home_screen.dart';

// ── Rutas centralizadas ───────────────────────────────────────────────────────

/// Constantes de rutas para evitar strings mágicos dispersos.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String registro = '/registro';
  static const String taller = '/taller';
  static const String inventario = '/taller/inventario';
  static const String lotes = '/taller/lotes';
  static const String cliente = '/cliente';
}

// ── Router factory ────────────────────────────────────────────────────────────

/// Fábrica del [GoRouter] de la aplicación.
///
/// Recibe [authViewModel] para que el router pueda escuchar cambios de estado
/// y recalcular las redirecciones reactivamente.
class AppRouter {
  AppRouter._();

  static GoRouter create(AuthViewModel authViewModel) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: true,

      // ── Listener reactivo ────────────────────────────────────────────────
      // Cuando [AuthViewModel] notifica cambios, el router re-evalúa el guard.
      refreshListenable: authViewModel,

      // ── Guard global (redirección por estado y rol) ───────────────────────
      redirect: (BuildContext context, GoRouterState state) {
        final status = authViewModel.status;
        final role = authViewModel.currentRole;
        final location = state.matchedLocation;

        // Rutas públicas (no requieren sesión).
        const publicRoutes = [
          AppRoutes.splash,
          AppRoutes.login,
          AppRoutes.registro,
        ];
        final isPublic = publicRoutes.contains(location);

        // Aún inicializando: dejamos pasar al splash.
        if (status == AuthStatus.initial) {
          return location == AppRoutes.splash ? null : AppRoutes.splash;
        }

        // Sin sesión: redirigir a login.
        if (status == AuthStatus.unauthenticated ||
            status == AuthStatus.error) {
          // Si estamos en el Splash, debemos enviarlo obligatoriamente al login.
          if (location == AppRoutes.splash) return AppRoutes.login;
          // Si ya está en login o registro (rutas públicas), lo dejamos ahí.
          return isPublic ? null : AppRoutes.login;
        }

        // Con sesión activa en ruta pública (login/registro): redirigir
        // automáticamente al área correspondiente al rol.
        if (status == AuthStatus.authenticated && isPublic) {
          return _homeForRole(role);
        }

        // Con sesión: verificar que el rol coincide con la ruta protegida.
        if (status == AuthStatus.authenticated) {
          if (location.startsWith('/taller') && role != UserRole.taller) {
            return _homeForRole(role);
          }
          if (location.startsWith('/cliente') && role != UserRole.cliente) {
            return _homeForRole(role);
          }
        }

        return null; // Sin redirección.
      },

      routes: [
        // ── Splash ────────────────────────────────────────────────────────
        GoRoute(
          path: AppRoutes.splash,
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // ── Autenticación ─────────────────────────────────────────────────
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.registro,
          name: 'registro',
          builder: (context, state) => const RegistroScreen(),
        ),

        // ── Área Taller ───────────────────────────────────────────────────
        GoRoute(
          path: AppRoutes.taller,
          name: 'taller',
          builder: (context, state) => const TallerHomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.inventario,
          name: 'inventario',
          builder: (context, state) => const InventarioScreen(),
        ),
        GoRoute(
          path: AppRoutes.lotes,
          name: 'lotes',
          builder: (context, state) => const LotesScreen(),
        ),

        // ── Área Cliente ──────────────────────────────────────────────────
        GoRoute(
          path: AppRoutes.cliente,
          name: 'cliente',
          builder: (context, state) => const ClienteHomeScreen(),
        ),
      ],

      // ── Pantalla de error global ──────────────────────────────────────────
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Página no encontrada.\n${state.error}',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  /// Devuelve la ruta de inicio según el [role] del usuario.
  static String _homeForRole(UserRole? role) {
    return switch (role) {
      UserRole.taller => AppRoutes.taller,
      UserRole.cliente => AppRoutes.cliente,
      null => AppRoutes.login,
    };
  }
}
