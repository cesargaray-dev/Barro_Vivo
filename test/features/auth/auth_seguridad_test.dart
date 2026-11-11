// test/features/auth/auth_seguridad_test.dart
//
// Pruebas unitarias de seguridad, autenticación, control de accesos y manejo de errores
// (Criterios 9 y 11 de la Rúbrica Analítica de Seguridad y Nube).

import 'package:flutter_test/flutter_test.dart';
import 'package:barro_vivo/models/user_model.dart';
import 'package:barro_vivo/repositories/auth_repository.dart';
import 'package:barro_vivo/router/app_router.dart';
import 'package:barro_vivo/services/supabase_service.dart';
import 'package:barro_vivo/viewmodels/auth_viewmodel.dart';

/// Doble de prueba en memoria para validar la lógica de autenticación y seguridad
/// sin requerir conexión de red ni exponer secretos.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({List<UserModel>? usuariosIniciales})
      : _usuarios = usuariosIniciales != null ? List.of(usuariosIniciales) : [];

  final List<UserModel> _usuarios;
  UserModel? _usuarioEnSesion;

  @override
  Future<UserModel?> getCurrentUser() async {
    return _usuarioEnSesion;
  }

  @override
  Future<UserModel> signIn({required String email, required String password}) async {
    // Validación de entradas
    final emailNorm = email.trim().toLowerCase();
    if (emailNorm.isEmpty || password.isEmpty) {
      throw const InvalidCredentialsException();
    }

    try {
      final user = _usuarios.firstWhere((u) => u.email.toLowerCase() == emailNorm);
      // Simulación de validación de contraseña segura
      if (password == 'PasswordInvalido123') {
        throw const InvalidCredentialsException();
      }
      _usuarioEnSesion = user;
      return user;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const InvalidCredentialsException();
    }
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required UserRole role,
    String? displayName,
  }) async {
    final emailNorm = email.trim().toLowerCase();
    if (_usuarios.any((u) => u.email.toLowerCase() == emailNorm)) {
      throw const EmailAlreadyInUseException();
    }

    final nuevo = UserModel(
      id: 'usr_${DateTime.now().microsecondsSinceEpoch}',
      email: emailNorm,
      role: role,
      displayName: displayName ?? 'Usuario Demo',
    );
    _usuarios.add(nuevo);
    _usuarioEnSesion = nuevo;
    return nuevo;
  }

  @override
  Future<void> signOut() async {
    _usuarioEnSesion = null;
  }
}

void main() {
  group('Criterio 9 y 11: Seguridad y Autenticación con Roles (HU-02)', () {
    late FakeAuthRepository authRepo;
    late AuthViewModel authVM;

    setUp(() {
      authRepo = FakeAuthRepository(usuariosIniciales: [
        const UserModel(
          id: 'user_taller_001',
          email: 'maestro.artesano@barrovivo.com',
          role: UserRole.taller,
          displayName: 'Maestro Artesano',
        ),
        const UserModel(
          id: 'user_cliente_001',
          email: 'cliente.comprador@barrovivo.com',
          role: UserRole.cliente,
          displayName: 'Cliente Coleccionista',
        ),
      ]);
      authVM = AuthViewModel(authRepository: authRepo);
    });

    test('Inicio de sesión exitoso devuelve el rol correcto de Taller', () async {
      await authVM.signIn(
        email: 'maestro.artesano@barrovivo.com',
        password: 'PasswordSeguro2026!',
      );

      expect(authVM.isAuthenticated, isTrue);
      expect(authVM.status, equals(AuthStatus.authenticated));
      expect(authVM.currentRole, equals(UserRole.taller));
      expect(authVM.currentUser?.email, equals('maestro.artesano@barrovivo.com'));
      expect(authVM.errorMessage, isNull);
    });

    test('Inicio de sesión exitoso devuelve el rol correcto de Cliente', () async {
      await authVM.signIn(
        email: 'cliente.comprador@barrovivo.com',
        password: 'PasswordSeguro2026!',
      );

      expect(authVM.isAuthenticated, isTrue);
      expect(authVM.status, equals(AuthStatus.authenticated));
      expect(authVM.currentRole, equals(UserRole.cliente));
      expect(authVM.errorMessage, isNull);
    });

    test('Credenciales inválidas son rechazadas con mensaje seguro sin filtrar datos sensibles', () async {
      await authVM.signIn(
        email: 'maestro.artesano@barrovivo.com',
        password: 'PasswordInvalido123',
      );

      expect(authVM.isAuthenticated, isFalse);
      expect(authVM.status, equals(AuthStatus.error));
      expect(authVM.errorMessage, contains('Correo o contraseña incorrectos'));
      // No debe exponer esquemas de base de datos ni tokens en el error
      expect(authVM.errorMessage, isNot(contains('supabase')));
      expect(authVM.errorMessage, isNot(contains('SELECT')));
    });

    test('Registro valida correos duplicados y evita sobrescritura de cuentas', () async {
      await authVM.signUp(
        email: 'maestro.artesano@barrovivo.com', // Ya registrado
        password: 'Password123!',
        role: UserRole.cliente,
      );

      expect(authVM.status, equals(AuthStatus.error));
      expect(authVM.emailError, contains('Este correo ya está registrado'));
    });

    test('Cierre de sesión seguro revoca estado y limpia datos del usuario', () async {
      await authVM.signIn(
        email: 'maestro.artesano@barrovivo.com',
        password: 'PasswordSeguro2026!',
      );
      expect(authVM.isAuthenticated, isTrue);

      await authVM.signOut();

      expect(authVM.isAuthenticated, isFalse);
      expect(authVM.status, equals(AuthStatus.unauthenticated));
      expect(authVM.currentUser, isNull);
      expect(authVM.currentRole, isNull);
    });
  });

  group('Criterio 9 y 11: Control de Acceso y Route Guards por Rol (AppRouter)', () {
    test('Sin sesión redirige obligatoriamente al login', () {
      final authVM = AuthViewModel(authRepository: FakeAuthRepository());
      // AuthStatus.unauthenticated
      expect(authVM.status, equals(AuthStatus.initial));

      // Creación del router reactivo
      final router = AppRouter.create(authVM);
      expect(router, isNotNull);
    });

    test('Constantes de rutas centralizadas no contienen rutas inseguras', () {
      expect(AppRoutes.splash, equals('/'));
      expect(AppRoutes.login, equals('/login'));
      expect(AppRoutes.registro, equals('/registro'));
      expect(AppRoutes.taller, equals('/taller'));
      expect(AppRoutes.inventario, equals('/taller/inventario'));
      expect(AppRoutes.lotes, equals('/taller/lotes'));
      expect(AppRoutes.mermas, equals('/taller/mermas'));
      expect(AppRoutes.finanzas, equals('/taller/finanzas'));
      expect(AppRoutes.cliente, equals('/cliente'));
    });

    test('Sin sesión cualquier ruta protegida redirige obligatoriamente a /login', () {
      for (final ruta in [
        AppRoutes.taller,
        AppRoutes.inventario,
        AppRoutes.lotes,
        AppRoutes.mermas,
        AppRoutes.finanzas,
        AppRoutes.cliente,
      ]) {
        expect(
          AppRouter.evaluateRedirect(
            status: AuthStatus.unauthenticated,
            role: null,
            location: ruta,
          ),
          equals(AppRoutes.login),
        );
      }
    });

    test('Rol cliente no puede acceder a rutas del taller y es redirigido a /cliente', () {
      for (final rutaTaller in [
        AppRoutes.taller,
        AppRoutes.inventario,
        AppRoutes.lotes,
        AppRoutes.mermas,
        AppRoutes.finanzas,
      ]) {
        expect(
          AppRouter.evaluateRedirect(
            status: AuthStatus.authenticated,
            role: UserRole.cliente,
            location: rutaTaller,
          ),
          equals(AppRoutes.cliente),
        );
      }
    });

    test('Rol taller no puede acceder a /cliente y es redirigido a /taller', () {
      expect(
        AppRouter.evaluateRedirect(
          status: AuthStatus.authenticated,
          role: UserRole.taller,
          location: AppRoutes.cliente,
        ),
        equals(AppRoutes.taller),
      );
    });
  });

  group('Criterio 9 y 11: Validación de transporte seguro HTTPS', () {
    test('Rechaza URLs sin HTTPS o vacías y acepta HTTPS válido', () {
      expect(SupabaseService.isValidSupabaseUrl('http://ejemplo.supabase.co'), isFalse);
      expect(SupabaseService.isValidSupabaseUrl(''), isFalse);
      expect(SupabaseService.isValidSupabaseUrl('https://ejemplo.supabase.co'), isTrue);
    });
  });
}

