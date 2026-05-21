import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import 'app_theme.dart';

/// Provider para el estilo de tema actual.
/// El tema se guarda por usuario usando su ID como parte de la clave
/// en FlutterSecureStorage, de modo que cada usuario mantiene su
/// preferencia de tema de forma independiente.
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeStyle>((
  ref,
) {
  final notifier = ThemeNotifier();

  // Escuchar cambios en el estado de autenticación para cargar/limpiar el tema
  ref.listen<AuthState>(authStateProvider, (previous, next) {
    next.maybeWhen(
      authenticated: (user) {
        notifier.loadThemeForUser(user.id);
      },
      unauthenticated: (_) {
        notifier.clearUser();
      },
      orElse: () {},
    );
  });

  // Intentar cargar el tema inicial si ya está autenticado al inicializarse el provider
  final currentAuth = ref.read(authStateProvider);
  currentAuth.maybeWhen(
    authenticated: (user) {
      notifier.loadThemeForUser(user.id);
    },
    unauthenticated: (_) {
      notifier.clearUser();
    },
    orElse: () {},
  );

  return notifier;
});

class ThemeNotifier extends StateNotifier<AppThemeStyle> {
  final _storage = const FlutterSecureStorage();
  static const _themeKeyPrefix = 'app_theme_style';

  /// ID del usuario actualmente autenticado; null si no hay sesión.
  String? _currentUserId;

  ThemeNotifier() : super(AppThemeStyle.light);

  /// Construye la clave de almacenamiento específica para cada usuario.
  /// Si no hay usuario autenticado, usa la clave genérica como fallback.
  String get _themeKey => _currentUserId != null
      ? '${_themeKeyPrefix}_$_currentUserId'
      : _themeKeyPrefix;

  /// Llamado cuando el usuario inicia sesión o cambia de cuenta.
  /// Carga la preferencia de tema almacenada para ese usuario.
  Future<void> loadThemeForUser(String userId) async {
    _currentUserId = userId;
    try {
      final savedTheme = await _storage.read(key: _themeKey);
      if (savedTheme != null) {
        state = AppThemeStyle.values.firstWhere(
          (t) => t.name == savedTheme,
          orElse: () => AppThemeStyle.light,
        );
      } else {
        // El usuario nunca ha elegido tema; usar light por defecto
        state = AppThemeStyle.light;
      }
    } catch (_) {
      state = AppThemeStyle.light;
    }
  }

  /// Llamado cuando el usuario cierra sesión.
  /// Resetea al tema por defecto sin userId.
  void clearUser() {
    _currentUserId = null;
    state = AppThemeStyle.light;
  }

  /// Cambia el tema y lo persiste asociado al usuario actual.
  Future<void> setTheme(AppThemeStyle themeStyle) async {
    state = themeStyle;
    await _storage.write(key: _themeKey, value: themeStyle.name);
  }
}
