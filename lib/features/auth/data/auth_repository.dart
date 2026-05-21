import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/models/auth_models.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/dio_provider.dart';
import '../../../core/network/dio_client.dart';

/// Provider del repositorio de autenticación
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthRepository(dioClient: dioClient);
});

class AuthRepository {
  final DioClient _dioClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthRepository({required DioClient dioClient}) : _dioClient = dioClient;

  Dio get _dio => _dioClient.dio;

  /// Iniciar sesión
  Future<AuthResponse> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    // El backend envuelve la respuesta en { success: true, data: { ... } }
    final data = response.data is Map && response.data['data'] != null
        ? response.data['data'] as Map<String, dynamic>
        : response.data as Map<String, dynamic>;

    final authResponse = AuthResponse.fromJson(data);

    // Guardar tokens
    await _dioClient.saveTokens(
      authResponse.accessToken,
      authResponse.refreshToken,
    );

    return authResponse;
  }

  /// Registrar nuevo usuario
  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await _dio.post('/auth/register', data: request.toJson());

    // El backend envuelve la respuesta en { success: true, data: { ... } }
    final data = response.data is Map && response.data['data'] != null
        ? response.data['data'] as Map<String, dynamic>
        : response.data as Map<String, dynamic>;

    final authResponse = AuthResponse.fromJson(data);

    // Guardar tokens
    await _dioClient.saveTokens(
      authResponse.accessToken,
      authResponse.refreshToken,
    );

    return authResponse;
  }

  /// Cerrar sesión
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // Ignorar error del servidor, siempre limpiar local
    }
    await _dioClient.clearTokens();
  }

  /// Obtener perfil del usuario actual
  Future<UserModel> getProfile() async {
    final response = await _dio.get('/auth/profile');
    // El backend envuelve la respuesta en { success: true, data: { ... } }
    final data = response.data is Map && response.data['data'] != null
        ? response.data['data'] as Map<String, dynamic>
        : response.data as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  /// Verificar si hay un token guardado (sesión activa)
  Future<bool> hasToken() async {
    final token = await _storage.read(key: 'access_token');
    return token != null && token.isNotEmpty;
  }

  /// Obtener el token actual
  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  /// Actualizar perfil del usuario
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.patch('/auth/profile', data: data);
    final result = response.data is Map && response.data['data'] != null
        ? response.data['data'] as Map<String, dynamic>
        : response.data as Map<String, dynamic>;
    return UserModel.fromJson(result);
  }

  /// Cambiar contraseña
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _dio.patch('/auth/password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}
