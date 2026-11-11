// lib/repositories/auth_repository.dart
//
// Capa de acceso a datos para autenticación – HU-02.
//
// Patrón: Repository con interfaz abstracta + implementación concreta Supabase.
// Los ViewModels dependen SOLO de [AuthRepository] (la abstracción).
// Supabase vive exclusivamente en [SupabaseAuthRepository].

// ignore: library_prefixes
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../models/user_model.dart';

// ── Excepciones del dominio ───────────────────────────────────────────────────

/// Error base de autenticación con mensaje legible para el usuario.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Credenciales inválidas (correo/contraseña incorrectos).
class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException()
      : super('Correo o contraseña incorrectos. Verifica tus datos.');
}

/// Correo ya registrado al intentar hacer registro.
class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException()
      : super('Este correo ya está registrado. Intenta iniciar sesión.');
}

/// Error genérico de red o servidor.
class NetworkAuthException extends AuthException {
  const NetworkAuthException(String detail)
      : super('Error de conexión. Verifica tu conexión e intenta de nuevo.');
}

// ── Interfaz ─────────────────────────────────────────────────────────────────

/// Contrato del repositorio de autenticación.
///
/// Permite sustituir la implementación real por un doble de prueba
/// sin modificar ningún ViewModel.
abstract class AuthRepository {
  /// Devuelve el usuario actualmente autenticado, o [null] si no hay sesión.
  Future<UserModel?> getCurrentUser();

  /// Inicia sesión con correo y contraseña.
  ///
  /// Lanza [InvalidCredentialsException] si las credenciales son inválidas.
  /// Lanza [NetworkAuthException] ante fallos de red.
  Future<UserModel> signIn({
    required String email,
    required String password,
  });

  /// Registra un nuevo usuario con correo, contraseña y rol.
  ///
  /// El rol se almacena en [user_metadata] de Supabase Auth.
  /// Lanza [EmailAlreadyInUseException] si el correo ya existe.
  Future<UserModel> signUp({
    required String email,
    required String password,
    required UserRole role,
    String? displayName,
  });

  /// Cierra la sesión activa.
  Future<void> signOut();
}

// ── Implementación concreta (Supabase) ────────────────────────────────────────

/// Implementación de [AuthRepository] que usa Supabase Auth.
///
/// Única clase del proyecto que importa [supabase_flutter].
/// Se instancia en el Composition Root ([main.dart]) y se inyecta
/// hacia arriba mediante [Provider].
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({supa.SupabaseClient? client})
      : _client = client ?? supa.Supabase.instance.client;

  final supa.SupabaseClient _client;

  // ── Helpers privados ──────────────────────────────────────────────────────

  /// Convierte un [User] de Supabase en [UserModel] de dominio.
  ///
  /// El rol se lee de [user_metadata['role']]; si no existe, se asigna
  /// 'cliente' como valor seguro por defecto.
  UserModel _mapUser(supa.User user) {
    final meta = user.userMetadata ?? {};
    final roleStr = meta['role'] as String? ?? UserRole.cliente.name;
    final role = UserRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => UserRole.cliente,
    );
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      role: role,
      displayName: meta['display_name'] as String?,
    );
  }

  /// Traduce las excepciones de Supabase a excepciones del dominio.
  Never _handleSupabaseError(Object e) {
    if (e is AuthException) throw e;

    if (e is supa.AuthException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('email not confirmed') ||
          msg.contains('invalid_credentials')) {
        throw const InvalidCredentialsException();
      }
      if (msg.contains('user already registered') ||
          msg.contains('email already')) {
        throw const EmailAlreadyInUseException();
      }
      throw AuthException(e.message);
    }

    throw NetworkAuthException(e.toString());
  }

  // ── Implementación de la interfaz ─────────────────────────────────────────

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) return null;
      final user = _client.auth.currentUser;
      if (user == null) return null;
      return _mapUser(user);
    } catch (_) {
      // Si no hay sesión válida retorna null; no es un error crítico.
      return null;
    }
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) throw const InvalidCredentialsException();
      return _mapUser(user);
    } catch (e) {
      _handleSupabaseError(e);
    }
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required UserRole role,
    String? displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'role': role.name,
          if (displayName != null) 'display_name': displayName,
        },
      );
      final user = response.user;
      if (user == null) throw const EmailAlreadyInUseException();
      return _mapUser(user);
    } catch (e) {
      _handleSupabaseError(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      _handleSupabaseError(e);
    }
  }
}
