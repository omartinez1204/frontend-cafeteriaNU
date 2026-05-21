import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../routing/app_router.dart';
import 'notification_sound_service.dart';

/// Servicio de notificaciones locales para CafeteriaNova.
///
/// Muestra notificaciones visibles con sonido cuando:
/// - El cliente recibe una actualización de estado de su pedido
/// - Caja/Cocina recibe un nuevo pedido
/// - El pedido está listo para recoger
///
/// RF-054: Notificaciones push en cada cambio de estado del ciclo del pedido
/// RF-055: Sonido y vibración según configuración del dispositivo
/// RF-056: Notificaciones de rechazo con motivo y mensaje alentador
/// RF-057: Alerta visual y sonora en caja/cocina al llegar nuevo pedido
///
/// Funciona tanto en foreground como background gracias a los canales
/// de Android con sonidos personalizados.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final NotificationSoundService _soundService = NotificationSoundService();

  bool _initialized = false;
  BuildContext? _navigatorContext;

  /// Inicializar el plugin de notificaciones locales.
  /// Debe llamarse al inicio de la app (en main.dart).
  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Crear los canales de Android con sonidos personalizados
    await _createNotificationChannels();

    await _soundService.init();

    _initialized = true;
    debugPrint('[NotificationService] Inicializado correctamente');
  }

  /// Crear canales de notificación de Android con sonidos específicos
  ///
  /// ⚠️ IMPORTANTE: Para que los sonidos personalizados funcionen en Android
  /// cuando la app está en segundo plano, los archivos .wav deben estar
  /// ubicados en android/app/src/main/res/raw/ con nombres en minúsculas
  /// y sin guiones bajos (ej: notification_ready.wav → notificationready.wav).
  ///
  /// flutter_local_notifications busca los sonidos en res/raw/ y usa el
  /// nombre del archivo sin extensión como URI de sonido.
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // ── Canal 1: Nuevo pedido (para caja/cocina) ──
    // Sonido: notification_new_order.wav
    const newOrderChannel = AndroidNotificationChannel(
      'new_order_channel',
      'Nuevos Pedidos',
      description: 'Notificaciones de nuevos pedidos entrantes',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notificationneworder'),
      enableVibration: true,
    );
    await androidPlugin.createNotificationChannel(newOrderChannel);

    // ── Canal 2: Pedido listo (para cliente) ──
    // Sonido: notification_ready.wav (sonido más fuerte y alegre)
    const readyChannel = AndroidNotificationChannel(
      'ready_channel',
      'Pedido Listo',
      description: 'Notificaciones cuando el pedido está listo para recoger',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notificationready'),
      enableVibration: true,
    );
    await androidPlugin.createNotificationChannel(readyChannel);

    // ── Canal 3: Genérico (para otros eventos) ──
    // Sonido: notification_generic.wav
    const genericChannel = AndroidNotificationChannel(
      'generic_channel',
      'Actualizaciones',
      description: 'Otras notificaciones de actualización de pedidos',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notificationgeneric'),
      enableVibration: true,
    );
    await androidPlugin.createNotificationChannel(genericChannel);

    // ── Canal 4: Canal legacy (por compatibilidad) ──
    const legacyChannel = AndroidNotificationChannel(
      'orders_channel',
      'Pedidos (legacy)',
      description: 'Canal de respaldo para notificaciones de pedidos',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await androidPlugin.createNotificationChannel(legacyChannel);

    debugPrint('[NotificationService] Canales de notificación creados con sonidos personalizados');
  }

  /// Establecer el contexto de navegación para redirigir al tocar una notificación
  void setNavigatorContext(BuildContext context) {
    _navigatorContext = context;
  }

  /// Manejar tap en notificación - redirige a la pantalla de pedidos
  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && _navigatorContext != null) {
      try {
        GoRouter.of(_navigatorContext!).go('/my-orders');
      } catch (_) {
        debugPrint('[NotificationService] Error al navegar desde notificación');
      }
    }
  }

  /// Mostrar una notificación local con sonido
  ///
  /// [channelId] determina qué sonido personalizado se usará:
  /// - 'new_order_channel' → notification_new_order.wav
  /// - 'ready_channel' → notification_ready.wav
  /// - 'generic_channel' → notification_generic.wav
  /// - null → 'orders_channel' (sonido por defecto del sistema)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? channelId,
    bool playSound = true,
  }) async {
    if (!_initialized) {
      debugPrint('[NotificationService] No inicializado, omitiendo notificación');
      return;
    }

    // Determinar el canal según el tipo de notificación
    // Si no se especifica, usar el canal genérico
    final effectiveChannelId = channelId ?? 'generic_channel';
    final channelName = _getChannelName(effectiveChannelId);
    final channelDescription = _getChannelDescription(effectiveChannelId);

    final androidDetails = AndroidNotificationDetails(
      effectiveChannelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: playSound,
      styleInformation: const DefaultStyleInformation(true, true),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: playSound,
      sound: 'default',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );

    debugPrint('[NotificationService] Notificación mostrada: $title (canal: $effectiveChannelId)');
  }

  /// Obtener el nombre legible del canal
  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'new_order_channel':
        return 'Nuevos Pedidos';
      case 'ready_channel':
        return 'Pedido Listo';
      case 'generic_channel':
        return 'Actualizaciones';
      default:
        return 'Pedidos';
    }
  }

  /// Obtener la descripción del canal
  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'new_order_channel':
        return 'Notificaciones de nuevos pedidos entrantes';
      case 'ready_channel':
        return 'Notificaciones cuando el pedido está listo para recoger';
      case 'generic_channel':
        return 'Otras notificaciones de actualización de pedidos';
      default:
        return 'Notificaciones de estado de pedidos';
    }
  }

  /// Mostrar notificación de nuevo pedido (para caja/cocina)
  /// RF-057: Alerta visual y sonora al llegar nuevo pedido
  Future<void> showNewOrderNotification({
    required String orderId,
    required String customerName,
    required String amount,
  }) async {
    // Reproducir sonido específico para nuevo pedido ANTES de la notificación
    // (para foreground - el canal ya tiene el sonido para background)
    await _soundService.playNewOrderSound();

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '🆕 Nuevo Pedido',
      body: '$customerName - \$$amount',
      payload: orderId,
      channelId: 'new_order_channel',
    );
  }

  /// Mostrar notificación de pedido en preparación (para cliente)
  /// RF-037: Cliente recibe notificación cuando su pedido está en preparación
  Future<void> showPreparingNotification({required String orderId}) async {
    await _soundService.playGenericSound();

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '👨‍🍳 Pedido en Preparación',
      body: 'Tu pedido está siendo preparado. ¡Estará listo pronto!',
      payload: orderId,
      channelId: 'generic_channel',
    );
  }

  /// Mostrar notificación de pedido listo (para cliente) - la más importante
  /// RF-040: Cliente recibe notificación cuando su pedido está listo
  Future<void> showReadyNotification({required String orderId}) async {
    // Sonido distintivo para pedido listo (el más importante)
    await _soundService.playReadySound();

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '✅ ¡Pedido Listo!',
      body: 'Tu pedido está listo para recoger. ¡Pasa por la cafetería!',
      payload: orderId,
      channelId: 'ready_channel',
    );
  }

  /// Mostrar notificación de pedido rechazado (para cliente)
  /// RF-056: Notificación de rechazo con motivo y mensaje alentador
  Future<void> showRejectedNotification({
    required String orderId,
    required String reason,
  }) async {
    await _soundService.playGenericSound();

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '❌ Pedido Rechazado',
      body: 'Tu pedido fue rechazado: $reason. ¡Pide otro producto!',
      payload: orderId,
      channelId: 'generic_channel',
    );
  }

  /// Mostrar notificación de pedido entregado (para cliente)
  /// RF-041: Cliente recibe notificación de cierre
  Future<void> showDeliveredNotification({required String orderId}) async {
    await _soundService.playGenericSound();

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '✅ Pedido Entregado',
      body: '¡Gracias por tu compra! Disfruta tu pedido.',
      payload: orderId,
      channelId: 'generic_channel',
    );
  }

  /// Mostrar notificación de confirmación de pedido creado (para cliente)
  Future<void> showOrderCreatedNotification({required String orderId}) async {
    await _soundService.playGenericSound();

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '📋 Pedido Recibido',
      body: 'Tu pedido ha sido registrado. Espera la confirmación de caja.',
      payload: orderId,
      channelId: 'generic_channel',
    );
  }

  /// Liberar recursos
  void dispose() {
    _soundService.dispose();
    _initialized = false;
  }
}

/// Provider del servicio de notificaciones
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  ref.onDispose(() => service.dispose());
  return service;
});
