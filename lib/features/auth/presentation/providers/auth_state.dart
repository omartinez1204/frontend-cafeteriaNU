import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/models/user_model.dart';

part 'auth_state.freezed.dart';

/// Estados posibles de la autenticación
@freezed
class AuthState with _$AuthState {
  /// Estado inicial, verificando si hay sesión activa
  const factory AuthState.initial() = _Initial;

  /// Cargando (login, register, verificando token)
  const factory AuthState.loading() = _Loading;

  /// Usuario autenticado
  const factory AuthState.authenticated(UserModel user) = _Authenticated;

  /// No autenticado
  const factory AuthState.unauthenticated({String? error}) = _Unauthenticated;

  /// Error de autenticación
  const factory AuthState.error(String message) = _Error;
}
