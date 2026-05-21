import 'dart:io';

/// Configuración de entorno para CafeteriaNova
class EnvConfig {
  EnvConfig._();

  /// URL base de la API (backend NestJS)
  /// En desarrollo: http://localhost:3000/api
  /// En producción: URL de Railway
  static String get apiUrl {
    // Detectar si estamos en web o dispositivo
    final isWeb = identical(0, 0.0); // truco para detectar web
    if (isWeb) {
      return const String.fromEnvironment(
        'API_URL',
        defaultValue: 'http://localhost:3000/api',
      );
    }
    // Android emulator usa 10.0.2.2 para localhost
    if (Platform.isAndroid) {
      return const String.fromEnvironment(
        'API_URL',
        defaultValue: 'http://10.0.2.2:3000/api',
      );
    }
    return const String.fromEnvironment(
      'API_URL',
      defaultValue: 'http://localhost:3000/api',
    );
  }

  /// URL base del servidor (sin /api) para recursos estáticos
  static String get serverUrl => apiUrl.replaceAll('/api', '');

  /// Construye la URL completa para una imagen local
  static String? getImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    if (path.startsWith('/')) {
      return '$serverUrl$path';
    }
    return '$serverUrl/$path';
  }

  /// URL del WebSocket
  static String get wsUrl {
    final base = serverUrl;
    return base.replaceAll('http', 'ws');
  }

  // Timeouts
  static const int CONNECT_TIMEOUT_MS = 10000;
  static const int RECEIVE_TIMEOUT_MS = 15000;
}
