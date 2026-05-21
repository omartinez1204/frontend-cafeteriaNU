import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../providers/dio_provider.dart';

/// Servicio para gestionar el token FCM (Firebase Cloud Messaging).
///
/// RF-054: Notificaciones push en cada cambio de estado del pedido.
/// RF-055: Sonido y vibracion segun configuracion del dispositivo.
///
/// Flujo:
/// 1. Obtiene el token FCM real del dispositivo via FirebaseMessaging
/// 2. Registra el token en el backend (PATCH /users/fcm-token)
/// 3. Escucha cambios de token y los re-registra automaticamente
/// 4. Refresca el token cada 24 horas como precaucion
class FcmService {
  final Dio _dio;
  String? _currentToken;
  Timer? _refreshTimer;
  StreamSubscription<String>? _tokenRefreshSub;

  FcmService(this._dio);

  /// Inicializar FCM: obtener token y registrarlo en el backend
  Future<void> init(String userId) async {
    final messaging = FirebaseMessaging.instance;

    // Solicitar permiso de notificaciones (iOS requiere esto)
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Obtener token FCM real del dispositivo
    final token = await messaging.getToken();
    if (token != null) {
      _currentToken = token;
      await _registerToken(userId, token);
      debugPrint('[FCM] Token real registrado en backend: ${token.substring(0, 20)}...');
    } else {
      debugPrint('[FCM] ⚠️ No se pudo obtener el token FCM');
    }

    // Escuchar cambios de token (ej. cuando la app se reinstala)
    _tokenRefreshSub = messaging.onTokenRefresh.listen((newToken) {
      _currentToken = newToken;
      _registerToken(userId, newToken);
      debugPrint('[FCM] Token renovado y registrado');
    });

    // Refrescar token cada 24 horas como respaldo
    _refreshTimer = Timer.periodic(
      const Duration(hours: 24),
      (_) async {
        if (_currentToken != null) {
          await _registerToken(userId, _currentToken!);
        }
      },
    );
  }

  /// Registrar/actualizar el token FCM en el backend
  Future<void> _registerToken(String userId, String token) async {
    try {
      await _dio.patch('/users/fcm-token', data: {
        'userId': userId,
        'fcmToken': token,
      });
    } catch (e) {
      debugPrint('[FCM] Error al registrar token: $e');
    }
  }

  /// Liberar recursos
  void dispose() {
    _refreshTimer?.cancel();
    _tokenRefreshSub?.cancel();
  }
}

/// Provider del servicio FCM
final fcmServiceProvider = Provider.family<FcmService, String>((ref, userId) {
  final dioClient = ref.watch(dioClientProvider);
  final service = FcmService(dioClient.dio);
  ref.onDispose(() => service.dispose());
  return service;
});
