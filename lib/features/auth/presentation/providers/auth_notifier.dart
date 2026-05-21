import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/models/user_model.dart';
import 'auth_state.dart';

/// Notifier que maneja la lógica de autenticación
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AuthState.initial());

  /// Verificar si hay sesión activa al iniciar la app
  Future<void> checkAuthStatus() async {
    state = const AuthState.loading();
    try {
      final hasToken = await _authRepository.hasToken();
      if (hasToken) {
        final user = await _authRepository.getProfile();
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      // Si falla al obtener perfil, forzar login
      state = const AuthState.unauthenticated();
    }
  }

  /// Iniciar sesión
  Future<void> login(String email, String password) async {
    state = const AuthState.loading();
    try {
      final response = await _authRepository.login(email, password);
      state = AuthState.authenticated(response.user);
    } catch (e) {
      state = AuthState.error(_extractErrorMessage(e));
    }
  }

  /// Registrar nuevo usuario
  /// Retorna true si el registro fue exitoso (usuario activo), false si requiere activación
  Future<bool> register(RegisterRequest request) async {
    state = const AuthState.loading();
    try {
      final response = await _authRepository.register(request);
      if (!response.user.isActive) {
        // Borrar tokens guardados por el repositorio
        await _authRepository.logout();
        state = const AuthState.error('REGISTRO_EXITOSO');
        return false; // Requiere activación presencial
      } else {
        state = AuthState.authenticated(response.user);
        return true; // Usuario activo directamente
      }
    } catch (e) {
      state = AuthState.error(_extractErrorMessage(e));
      return false;
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    await _authRepository.logout();
    state = const AuthState.unauthenticated();
  }

  /// Actualizar datos del usuario en el estado actual
  void updateUser(UserModel user) {
    state = AuthState.authenticated(user);
  }

  /// Limpiar error
  void clearError() {
    state = const AuthState.unauthenticated();
  }

  /// Extraer mensaje de error de una excepción
  String _extractErrorMessage(dynamic error) {
    if (error is Exception) {
      final errorStr = error.toString();
      if (errorStr.contains('401')) return 'Credenciales inválidas';
      if (errorStr.contains('409')) return 'El email ya está registrado';
      if (errorStr.contains('SocketException') ||
          errorStr.contains('Connection refused')) {
        return 'Error de conexión con el servidor';
      }
    }
    return 'Error inesperado. Intenta de nuevo.';
  }
}

/// Provider del estado de autenticación
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});
