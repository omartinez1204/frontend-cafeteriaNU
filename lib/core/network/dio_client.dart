import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/env_config.dart';

/// Cliente Dio configurado para CafeteriaNova.
///
/// Características:
/// - Base URL desde [EnvConfig]
/// - Interceptor que agrega automáticamente el token JWT
/// - Manejo de refresh token cuando expira el access token
/// - Logging en desarrollo
class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiUrl,
        connectTimeout: Duration(milliseconds: EnvConfig.CONNECT_TIMEOUT_MS),
        receiveTimeout: Duration(milliseconds: EnvConfig.RECEIVE_TIMEOUT_MS),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('[DIO] $obj'),
    ));
  }

  /// Obtiene la instancia de Dio para usar con Riverpod providers
  Dio get dio => _dio;

  /// Interceptor que agrega el token JWT a cada request
  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // No agregar token para login/register
        if (options.path.contains('/auth/login') || options.path.contains('/auth/register')) {
          return handler.next(options);
        }

        final token = await _storage.read(key: _accessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Si recibimos 401, intentamos refrescar el token
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            // Reintentar la petición original con el nuevo token
            final newToken = await _storage.read(key: _accessTokenKey);
            error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final retryResponse = await _dio.fetch(error.requestOptions);
            return handler.resolve(retryResponse);
          }
        }
        return handler.next(error);
      },
    );
  }

  /// Intenta refrescar el access token usando el refresh token
  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await Dio(
        BaseOptions(baseUrl: EnvConfig.apiUrl),
      ).post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200) {
        // El backend envuelve la respuesta en { success: true, data: { ... } }
        final rawData = response.data is Map && response.data['data'] != null
            ? response.data['data'] as Map<String, dynamic>
            : response.data as Map<String, dynamic>;
        await _storage.write(key: _accessTokenKey, value: rawData['accessToken']);
        if (rawData['refreshToken'] != null) {
          await _storage.write(key: _refreshTokenKey, value: rawData['refreshToken']);
        }
        return true;
      }
      return false;
    } catch (e) {
      // Si falla el refresh, limpiamos tokens y forzamos login
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      return false;
    }
  }

  /// Guarda los tokens después de login exitoso
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// Limpia los tokens (logout)
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
