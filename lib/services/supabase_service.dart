// lib/services/supabase_service.dart
//
// Servicio centralizado de Supabase implementado como Singleton.
//
// ⚠️  Las credenciales se inyectan en compilación/ejecución mediante .env (--dart-define-from-file=.env)

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuración del cliente de Supabase.
class SupabaseService {
  SupabaseService._();

  // ── Credenciales ─────────────────────────────────────────────────────────
  // Se inyectan en compilación/ejecución mediante .env (--dart-define-from-file=.env)
  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Acceso directo al [SupabaseClient] después de [initialize()].
  static SupabaseClient get client => Supabase.instance.client;

  /// Inicializa el SDK de Supabase.
  ///
  /// Debe invocarse una sola vez en [main()] antes de [runApp()].
  static Future<void> initialize() async {
    if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
      debugPrint(
        '[SupabaseService] ⚠️ ERROR CRÍTICO: SUPABASE_URL o SUPABASE_ANON_KEY no están definidas.\n'
        'Asegúrate de pasar --dart-define-from-file=.env al compilar/ejecutar la aplicación.',
      );
    }

    try {
      await Supabase.initialize(
        url: _supabaseUrl,
        publishableKey: _supabaseAnonKey,
        // Habilitar la persistencia de sesión local.
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        // Nivel de log: solo errores en producción.
        debug: false,
      );
    } catch (e) {
      debugPrint('[SupabaseService] Advertencia al inicializar Supabase: $e');
    }
  }
}
