import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/websocket_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/notification_controller.dart';
import 'core/services/fcm_service.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/providers/auth_notifier.dart';
import 'core/theme/theme_provider.dart';

/// Handler de notificaciones en background.
/// Se ejecuta en un isolate separado cuando la app esta cerrada o en segundo plano.
/// Muestra una notificacion local con sonido usando flutter_local_notifications.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inicializar Firebase para el isolate secundario
  await Firebase.initializeApp();

  // Inicializar el plugin de notificaciones locales
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(initSettings);

  // Crear canales de Android para el isolate secundario
  // con sonidos personalizados para cada tipo de notificacion
  final androidPlugin =
      plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'new_order_channel',
        'Nuevos Pedidos',
        description: 'Notificaciones de nuevos pedidos entrantes',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notificationneworder'),
        enableVibration: true,
      ),
    );
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'ready_channel',
        'Pedido Listo',
        description: 'Notificaciones cuando el pedido esta listo para recoger',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notificationready'),
        enableVibration: true,
      ),
    );
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'generic_channel',
        'Actualizaciones',
        description: 'Otras notificaciones de actualizacion de pedidos',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notificationgeneric'),
        enableVibration: true,
      ),
    );
  }

  // Mostrar la notificacion local
  final notification = message.notification;
  if (notification != null) {
    // Seleccionar el canal correcto segun el tipo de notificacion
    final dataType = message.data['type'] ?? '';
    final String channelId;
    final String channelName;
    if (dataType == 'ready') {
      channelId = 'ready_channel';
      channelName = 'Pedido Listo';
    } else if (dataType == 'new_order') {
      channelId = 'new_order_channel';
      channelName = 'Nuevos Pedidos';
    } else {
      channelId = 'generic_channel';
      channelName = 'Actualizaciones';
    }

    await plugin.show(
      message.hashCode,
      notification.title ?? 'CafeteriaNova',
      notification.body ?? 'Actualizacion de tu pedido',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Notificaciones de CafeteriaNova',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        ),
      ),
      payload: message.data['orderId'] ?? '',
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase ANTES de cualquier otra cosa
  await Firebase.initializeApp();

  // Registrar el handler de background messages
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Inicializar el servicio de notificaciones locales
  final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    ProviderScope(
      overrides: [
        // Proveer la instancia ya inicializada del servicio de notificaciones
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: CafeteriaNovaApp(),
    ),
  );
}

class CafeteriaNovaApp extends ConsumerStatefulWidget {
  const CafeteriaNovaApp({super.key});

  @override
  ConsumerState<CafeteriaNovaApp> createState() => _CafeteriaNovaAppState();
}

class _CafeteriaNovaAppState extends ConsumerState<CafeteriaNovaApp> {
  // Rastrea el userId actual para limpiar el controlador anterior al cambiar de usuario
  String? _previousUserId;

  @override
  void initState() {
    super.initState();

    // Configurar handler de notificaciones en foreground.
    // Cuando la app esta abierta y llega una notificacion FCM, mostramos
    // una notificacion local con sonido.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Notificacion en foreground: ${message.notification?.title}');
      final notification = message.notification;
      if (notification != null) {
        // Seleccionar el canal correcto segun el tipo de notificacion
        final dataType = message.data['type'] ?? '';
        final String channelId;
        if (dataType == 'ready') {
          channelId = 'ready_channel';
        } else if (dataType == 'new_order') {
          channelId = 'new_order_channel';
        } else {
          channelId = 'generic_channel';
        }
        ref.read(notificationServiceProvider).showNotification(
          id: message.hashCode,
          title: notification.title ?? 'CafeteriaNova',
          body: notification.body ?? 'Actualizacion de tu pedido',
          payload: message.data['orderId'] ?? '',
          channelId: channelId,
        );
      }
    });

    // Cuando el usuario toca una notificacion y la app estaba en background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Notificacion abierta desde background');
      // Navegar a mis pedidos
      final router = ref.read(goRouterProvider);
      router.go('/my-orders');
    });

    // Si la app se abrio desde una notificacion (estaba completamente cerrada)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('[FCM] App abierta desde notificacion');
        Future.delayed(const Duration(milliseconds: 500), () {
          final router = ref.read(goRouterProvider);
          router.go('/my-orders');
        });
      }
    });

    // Reaccionar a cambios de autenticacion para WebSockets, FCM y notificaciones
    ref.listenManual(authStateProvider, (previous, next) {
      next.maybeWhen(
        authenticated: (user) {
          if (_previousUserId != null && _previousUserId != user.id) {
            debugPrint('[main] Usuario cambio: $_previousUserId → ${user.id}, limpiando controlador anterior');
            ref.invalidate(notificationControllerProvider(_previousUserId!));
          }
          _previousUserId = user.id;

          ref.read(authRepositoryProvider).getToken().then((token) {
            if (token != null) {
              final wsService = ref.read(webSocketServiceProvider);

              if (wsService.isConnected) {
                wsService.disconnect();
              }

              wsService.connect(token: token);

              ref.read(notificationControllerProvider(user.id)).startListening(
                userId: user.id,
                userRole: user.role,
              );
            }
          });

          // Inicializar FCM con token real de Firebase
          ref.read(fcmServiceProvider(user.id)).init(user.id);
        },
        unauthenticated: (_) {
          if (_previousUserId != null) {
            ref.invalidate(notificationControllerProvider(_previousUserId!));
            _previousUserId = null;
          }
          ref.read(webSocketServiceProvider).disconnect();
        },
        orElse: () {},
      );
    });

    // Verificar sesion al iniciar la app
    Future.microtask(() {
      ref.read(authStateProvider.notifier).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final themeStyle = ref.watch(themeProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).setNavigatorContext(context);
    });

    return MaterialApp.router(
      title: 'CafeteriaNova',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(themeStyle),
      routerConfig: router,
    );
  }
}
