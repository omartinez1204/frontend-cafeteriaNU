# CafeteriaNova App — Flutter + Riverpod

**Repositorio:** `cafeterianova-app`  
**Stack:** Flutter 3.x · Riverpod · GoRouter · firebase_messaging · socket_io_client  
**Versión:** 1.0  
**Última actualización:** Julio 2025

---

## 📖 Contexto del Proyecto

Este repositorio contiene la aplicación móvil completa de CafeteriaNova para iOS y Android. Para contexto general del proyecto, roles, ciclo de pedido y convenciones, **SIEMPRE consulta primero el archivo maestro:**

📄 **`../.agents/CLAUDE.md`** — Contexto maestro del proyecto completo

Este archivo (`CLAUDE.md` de Flutter) extiende el maestro con detalles específicos de implementación móvil.

---

## 🎯 Responsabilidades de Esta App

1. **Interfaz de cliente** para hacer pedidos con restricciones y notas
2. **Historial de pedidos** con estados en tiempo real vía WebSocket
3. **Notificaciones push** (FCM) para cambios de estado de pedidos
4. **Pantalla de cocina** (solo rol cocina) — display de tarjetas en tiempo real
5. **Panel de caja** (solo admin/cajero) — aceptar/rechazar pedidos
6. **Sistema de temas** (institucional, dark, light, sistema)
7. **Autenticación JWT** con refresh token automático
8. **Gestión de perfil** con selección de tema y visualización de becas

---

## 🏗️ Estructura del Proyecto (Feature-Based)

```
lib/
├── main.dart
├── app.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── dtos/
│   │   │   │   ├── login_request_dto.dart
│   │   │   │   ├── register_request_dto.dart
│   │   │   │   └── auth_response_dto.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart
│   │   ├── domain/
│   │   │   └── models/
│   │   │       └── user.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── auth_provider.dart
│   │       │   └── auth_state_provider.dart
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   ├── register_screen.dart
│   │       │   └── activation_pending_screen.dart
│   │       └── widgets/
│   │           ├── auth_text_field.dart
│   │           └── role_selector.dart
│   │
│   ├── menu/
│   │   ├── data/
│   │   │   ├── dtos/
│   │   │   │   └── product_dto.dart
│   │   │   └── repositories/
│   │   │       └── menu_repository.dart
│   │   ├── domain/
│   │   │   └── models/
│   │   │       ├── product.dart
│   │   │       └── menu_item.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── menu_provider.dart
│   │       │   └── selected_restrictions_provider.dart
│   │       ├── screens/
│   │       │   ├── menu_screen.dart
│   │       │   └── product_detail_screen.dart
│   │       └── widgets/
│   │           ├── product_card.dart
│   │           ├── category_filter.dart
│   │           └── restriction_chip.dart
│   │
│   ├── orders/              # ⭐ MÓDULO CRÍTICO (cliente)
│   │   ├── data/
│   │   │   ├── dtos/
│   │   │   │   ├── create_order_dto.dart
│   │   │   │   └── order_dto.dart
│   │   │   └── repositories/
│   │   │       └── orders_repository.dart
│   │   ├── domain/
│   │   │   └── models/
│   │   │       ├── order.dart
│   │   │       └── order_status.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── orders_list_provider.dart
│   │       │   ├── current_order_provider.dart
│   │       │   └── order_socket_provider.dart
│   │       ├── screens/
│   │       │   ├── orders_screen.dart
│   │       │   ├── order_detail_screen.dart
│   │       │   └── create_order_screen.dart
│   │       └── widgets/
│   │           ├── order_card.dart
│   │           ├── order_status_badge.dart
│   │           ├── order_timeline.dart
│   │           └── customer_note_field.dart
│   │
│   ├── kitchen/             # Solo rol 'cocina'
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── kitchen_repository.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── kitchen_orders_provider.dart
│   │       ├── screens/
│   │       │   └── kitchen_display_screen.dart
│   │       └── widgets/
│   │           ├── kitchen_order_card.dart
│   │           └── rejection_reason_dialog.dart
│   │
│   ├── cashier/             # Solo roles 'admin' y 'cajero'
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── cashier_repository.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── cashier_orders_provider.dart
│   │       ├── screens/
│   │       │   └── cashier_panel_screen.dart
│   │       └── widgets/
│   │           ├── pending_order_card.dart
│   │           └── accept_reject_buttons.dart
│   │
│   └── profile/
│       ├── data/
│       │   └── repositories/
│       │       └── profile_repository.dart
│       └── presentation/
│           ├── providers/
│           │   ├── profile_provider.dart
│           │   └── theme_provider.dart
│           ├── screens/
│           │   └── profile_screen.dart
│           └── widgets/
│               ├── theme_selector.dart
│               └── scholarship_badge.dart
│
├── core/
│   ├── theme/
│   │   ├── app_colors.dart           # NovaUniversitas colors
│   │   ├── app_theme.dart            # ThemeData definitions
│   │   └── text_styles.dart
│   ├── router/
│   │   ├── app_router.dart           # GoRouter configuration
│   │   └── guards/
│   │       └── role_guard.dart
│   ├── network/
│   │   ├── dio_client.dart           # Dio + interceptors
│   │   ├── api_endpoints.dart
│   │   └── api_response.dart
│   ├── notifications/
│   │   ├── fcm_handler.dart          # Firebase Cloud Messaging
│   │   └── notification_service.dart
│   ├── websocket/
│   │   └── socket_service.dart       # Socket.io client
│   ├── storage/
│   │   └── secure_storage.dart       # JWT tokens storage
│   └── constants/
│       ├── app_constants.dart
│       └── env_config.dart
│
└── shared/
    ├── widgets/
    │   ├── nova_button.dart
    │   ├── nova_card.dart
    │   ├── nova_text_field.dart
    │   ├── loading_indicator.dart
    │   └── error_view.dart
    ├── models/
    │   └── failure.dart
    └── extensions/
        ├── context_extensions.dart
        └── datetime_extensions.dart
```

---

## 🔧 Configuración Inicial

### Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.5.0

  # Routing
  go_router: ^14.0.0

  # HTTP Client
  dio: ^5.4.0

  # Firebase
  firebase_core: ^2.24.0
  firebase_messaging: ^14.7.0

  # Real-time WebSocket
  socket_io_client: ^2.0.3

  # Animations
  flutter_animate: ^4.5.0
  lottie: ^3.0.0

  # Storage
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.2

  # Images
  cached_network_image: ^3.3.0

  # Utils
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  intl: ^0.18.1
  dartz: ^0.10.1  # Either pattern for error handling

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code generation
  build_runner: ^2.4.7
  riverpod_generator: ^2.4.0
  freezed: ^2.4.6
  json_serializable: ^6.7.1

  # Linting
  flutter_lints: ^3.0.0
```

### Configuración de Firebase

1. **Firebase Console** → Crear proyecto `cafeterianova-dev`
2. **Agregar apps** iOS y Android
3. **Descargar archivos de configuración:**
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`
   - Android: `google-services.json` → `android/app/`

4. **FlutterFire CLI:**
```bash
# Instalar FlutterFire CLI
dart pub global activate flutterfire_cli

# Configurar Firebase
flutterfire configure
```

### Variables de Entorno

Crear archivos `.env.development`, `.env.staging`, `.env.production`:

```dart
// lib/core/constants/env_config.dart
class EnvConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',  // Android emulator
  );

  static const wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static const environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
}
```

**Run con flavor:**
```bash
flutter run --dart-define=API_BASE_URL=https://cafeterianova.railway.app \
            --dart-define=WS_BASE_URL=https://cafeterianova.railway.app \
            --dart-define=ENVIRONMENT=production
```

---

## 🎨 Sistema de Temas (NovaUniversitas)

### App Colors

```dart
// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class NovaColors {
  // Colores primarios institucionales
  static const Color greenDark = Color(0xFF1A4731);
  static const Color greenMedium = Color(0xFF2E7D52);
  static const Color greenLight = Color(0xFFD4EDDA);
  static const Color gold = Color(0xFFC8960C);
  static const Color goldLight = Color(0xFFFFF8E1);

  // Colores semánticos (estados de pedido)
  static const Color statusReady = Color(0xFF1B5E20);       // LISTO_PARA_ENTREGAR
  static const Color statusInProgress = Color(0xFFE65100);  // EN_PREPARACION
  static const Color statusRejected = Color(0xFFB71C1C);    // RECHAZADO_*

  // Neutrales
  static const Color grayLight = Color(0xFFF4F6F4);
  static const Color grayMedium = Color(0xFFDEE3DE);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Nunca usar colores hardcodeados en widgets
  // Siempre usar Theme.of(context).colorScheme o estas constantes
}
```

### Theme Definitions

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // Tema institucional NovaUniversitas (DEFAULT)
  static ThemeData get institutionalTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: NovaColors.greenMedium,
          primary: NovaColors.greenMedium,
          secondary: NovaColors.gold,
          surface: NovaColors.white,
          background: NovaColors.grayLight,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: NovaColors.greenDark,
          foregroundColor: NovaColors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: NovaColors.greenMedium,
            foregroundColor: NovaColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );

  // Tema oscuro
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: NovaColors.greenMedium,
          brightness: Brightness.dark,
          primary: NovaColors.gold,
          secondary: NovaColors.greenLight,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: NovaColors.greenDark,
          foregroundColor: NovaColors.white,
          elevation: 0,
          centerTitle: true,
        ),
      );

  // Tema claro
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: NovaColors.greenMedium,
          brightness: Brightness.light,
          primary: NovaColors.greenMedium,
          secondary: NovaColors.gold,
        ),
      );
}
```

### Theme Provider

```dart
// lib/features/profile/presentation/providers/theme_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_provider.g.dart';

enum AppThemeMode {
  institutional,
  dark,
  light,
  system;

  static AppThemeMode fromString(String name) {
    return AppThemeMode.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AppThemeMode.institutional,
    );
  }
}

@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  static const _key = 'theme_mode';

  @override
  AppThemeMode build() {
    _loadTheme();
    return AppThemeMode.institutional;  // Default
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_key) ?? 'institutional';
    state = AppThemeMode.fromString(themeName);
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}
```

---

## 🔐 Autenticación JWT con Refresh Token

### Dio Client con Interceptores

```dart
// lib/core/network/dio_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../constants/env_config.dart';

part 'dio_client.g.dart';

@riverpod
Dio dioClient(DioClientRef ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: '${EnvConfig.apiBaseUrl}/api/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Interceptor para agregar JWT token
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        const storage = FlutterSecureStorage();
        final token = await storage.read(key: 'access_token');
        
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Si el error es 401 (Unauthorized), intentar refresh token
        if (error.response?.statusCode == 401) {
          try {
            const storage = FlutterSecureStorage();
            final refreshToken = await storage.read(key: 'refresh_token');

            if (refreshToken == null) {
              return handler.reject(error);
            }

            // Llamar al endpoint de refresh
            final refreshDio = Dio(BaseOptions(
              baseUrl: '${EnvConfig.apiBaseUrl}/api/v1',
            ));

            final response = await refreshDio.post(
              '/auth/refresh',
              data: {'refreshToken': refreshToken},
            );

            final newAccessToken = response.data['accessToken'];
            final newRefreshToken = response.data['refreshToken'];

            // Guardar nuevos tokens
            await storage.write(key: 'access_token', value: newAccessToken);
            await storage.write(key: 'refresh_token', value: newRefreshToken);

            // Reintentar request original con nuevo token
            error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            final retryResponse = await dio.fetch(error.requestOptions);
            return handler.resolve(retryResponse);
          } catch (e) {
            // Si refresh falla, logout
            const storage = FlutterSecureStorage();
            await storage.deleteAll();
            return handler.reject(error);
          }
        }

        return handler.next(error);
      },
    ),
  );

  // Logging interceptor (solo en desarrollo)
  if (EnvConfig.isDevelopment) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  return dio;
}
```

---

## 🔄 State Management con Riverpod

### Ejemplo: Orders List Provider

```dart
// lib/features/orders/presentation/providers/orders_list_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/orders_repository.dart';
import '../../domain/models/order.dart';

part 'orders_list_provider.g.dart';

@riverpod
class OrdersList extends _$OrdersList {
  @override
  FutureOr<List<Order>> build() async {
    return _fetchOrders();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchOrders);
  }

  Future<List<Order>> _fetchOrders() async {
    final repository = ref.read(ordersRepositoryProvider);
    final result = await repository.getMyOrders();
    
    return result.fold(
      (failure) => throw failure,
      (orders) => orders,
    );
  }

  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    state.whenData((orders) {
      final updatedOrders = orders.map((order) {
        if (order.id == orderId) {
          return order.copyWith(currentStatus: newStatus);
        }
        return order;
      }).toList();

      state = AsyncValue.data(updatedOrders);
    });
  }
}
```

### Uso en Widget

```dart
// lib/features/orders/presentation/screens/orders_screen.dart
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Pedidos')),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Text('No tienes pedidos aún'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(ordersListProvider.notifier).refresh(),
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return OrderCard(order: orders[index])
                    .animate()
                    .fadeIn(duration: 300.ms, delay: (index * 50).ms)
                    .slideY(begin: 0.2, end: 0, duration: 300.ms, delay: (index * 50).ms);
              },
            ),
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(ordersListProvider),
        ),
      ),
    );
  }
}
```

---

## 🌐 WebSocket en Tiempo Real (Socket.io)

### Socket Service

```dart
// lib/core/websocket/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../constants/env_config.dart';

part 'socket_service.g.dart';

@riverpod
IO.Socket socketClient(SocketClientRef ref) {
  final socket = IO.io(
    EnvConfig.wsBaseUrl,
    IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build(),
  );

  socket.onConnect((_) => print('Socket connected'));
  socket.onDisconnect((_) => print('Socket disconnected'));
  socket.onConnectError((data) => print('Socket error: $data'));

  socket.connect();

  ref.onDispose(() {
    socket.disconnect();
    socket.dispose();
  });

  return socket;
}

// Provider para escuchar cambios de estado de un pedido específico
@riverpod
Stream<OrderStatusUpdate> orderStatusUpdates(
  OrderStatusUpdatesRef ref,
  String orderId,
) async* {
  final socket = ref.watch(socketClientProvider);

  // Join room del pedido
  socket.emit('join-order', orderId);

  // Escuchar eventos
  await for (final event in socket.fromEvent('order:status-changed')) {
    yield OrderStatusUpdate.fromJson(event as Map<String, dynamic>);
  }
}
```

### Uso en Widget

```dart
class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({required this.orderId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusUpdatesAsync = ref.watch(orderStatusUpdatesProvider(orderId));

    // Escuchar cambios de estado en tiempo real
    ref.listen<AsyncValue<OrderStatusUpdate>>(
      orderStatusUpdatesProvider(orderId),
      (previous, next) {
        next.whenData((update) {
          // Actualizar el estado local del pedido
          ref.read(ordersListProvider.notifier).updateOrderStatus(
                orderId,
                update.status,
              );

          // Mostrar animación si está listo
          if (update.status == OrderStatus.listoParaEntregar) {
            _showReadyAnimation(context);
          }
        });
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Pedido')),
      body: OrderDetailView(orderId: orderId),
    );
  }

  void _showReadyAnimation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LottieAnimationDialog(
        animationPath: 'assets/animations/order_ready.json',
        message: '¡Tu pedido está listo!',
      ),
    );
  }
}
```

---

## 🔔 Firebase Cloud Messaging

### FCM Handler

```dart
// lib/core/notifications/fcm_handler.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FCMHandler {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final Ref _ref;

  FCMHandler(this._ref);

  Future<void> initialize() async {
    // Request permissions (iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print('Notifications permission denied');
      return;
    }

    // Get FCM token
    final token = await _fcm.getToken();
    if (token != null) {
      await _sendTokenToBackend(token);
    }

    // Listen for token refresh
    _fcm.onTokenRefresh.listen(_sendTokenToBackend);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages (top-level function)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification tap (app opened from terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from terminated state
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      // Show in-app notification banner
      _showInAppNotification(
        title: notification.title ?? '',
        body: notification.body ?? '',
        data: data,
      );
    }

    // Update order status if it's an order notification
    if (data['orderId'] != null) {
      final orderId = data['orderId'] as String;
      final status = OrderStatus.fromString(data['status'] as String);
      
      _ref.read(ordersListProvider.notifier).updateOrderStatus(orderId, status);
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;

    // Navigate based on data.route
    if (data['route'] != null) {
      // Use GoRouter to navigate
      final router = _ref.read(appRouterProvider);
      router.push(data['route']);
    }
  }

  void _showInAppNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    // Implementar banner de notificación in-app
    // Puede usar un SnackBar o un overlay widget personalizado
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final dio = _ref.read(dioClientProvider);
      await dio.patch('/users/me/fcm-token', data: {'fcmToken': token});
    } catch (e) {
      print('Error sending FCM token to backend: $e');
    }
  }
}

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message: ${message.messageId}');
  // Cannot update UI here — only show local notification
}
```

---

## 🎨 Animaciones con flutter_animate

### Entrance Animation (Lista de Productos)

```dart
class MenuGrid extends StatelessWidget {
  final List<Product> products;

  const MenuGrid({required this.products, super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCard(product: products[index])
            .animate()
            .fadeIn(
              duration: const Duration(milliseconds: 300),
              delay: Duration(milliseconds: index * 50),
            )
            .slideY(
              begin: 0.2,
              end: 0,
              duration: const Duration(milliseconds: 300),
              delay: Duration(milliseconds: index * 50),
            );
      },
    );
  }
}
```

### Button Tap Animation

```dart
class NovaButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final bool isLoading;

  const NovaButton({
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: NovaColors.greenMedium,
          borderRadius: BorderRadius.circular(8),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      )
          .animate(onPlay: (controller) => controller.forward())
          .scale(
            duration: const Duration(milliseconds: 100),
            begin: const Offset(1, 1),
            end: const Offset(0.95, 0.95),
            curve: Curves.easeOut,
          )
          .then()
          .scale(
            duration: const Duration(milliseconds: 100),
            begin: const Offset(0.95, 0.95),
            end: const Offset(1, 1),
            curve: Curves.easeIn,
          ),
    );
  }
}
```

---

## 🧭 Navegación con GoRouter

```dart
// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/menu',
    redirect: (context, state) {
      final isAuthenticated = authState.value?.isAuthenticated ?? false;
      final userRole = authState.value?.user.role;

      // Redirect unauthenticated users
      if (!isAuthenticated && !state.matchedLocation.startsWith('/auth')) {
        return '/auth/login';
      }

      // Role-based protection
      if (state.matchedLocation.startsWith('/kitchen')) {
        if (userRole != UserRole.cocina) {
          return '/menu';
        }
      }

      if (state.matchedLocation.startsWith('/cashier')) {
        if (userRole != UserRole.admin && userRole != UserRole.cajero) {
          return '/menu';
        }
      }

      return null;  // No redirect
    },
    routes: [
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/menu',
        builder: (context, state) => const MenuScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final orderId = state.pathParameters['id']!;
              return OrderDetailScreen(orderId: orderId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/kitchen',
        builder: (context, state) => const KitchenDisplayScreen(),
      ),
      GoRoute(
        path: '/cashier',
        builder: (context, state) => const CashierPanelScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
```

---

## ⚠️ Reglas Críticas de Este App

### NUNCA

- ❌ Usar `setState` — siempre Riverpod providers
- ❌ Usar `FutureProvider` directamente en widgets — wrap en `AsyncNotifierProvider`
- ❌ Hardcodear colores — usar `NovaColors` o `Theme.of(context)`
- ❌ Olvidar agregar `Semantics` en widgets interactivos (accesibilidad)
- ❌ Usar `AnimationController` manualmente — preferir `flutter_animate`

### SIEMPRE

- ✅ Usar estructura feature-based
- ✅ Implementar error handling con `Either` pattern
- ✅ Agregar loading states a `AsyncValue.when`
- ✅ Usar `const` constructors donde sea posible
- ✅ Agregar `key` a widgets animados (`ValueKey`)
- ✅ Testear en iOS y Android

---

## 🚀 Comandos de Desarrollo

```bash
# Run en desarrollo
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

# Run en staging
flutter run --dart-define=API_BASE_URL=https://cafeterianova-staging.railway.app \
            --dart-define=ENVIRONMENT=staging

# Run en producción
flutter run --release \
            --dart-define=API_BASE_URL=https://cafeterianova.railway.app \
            --dart-define=ENVIRONMENT=production

# Generar código (Riverpod, Freezed, JSON)
flutter pub run build_runner build --delete-conflicting-outputs

# Generar código en watch mode
flutter pub run build_runner watch --delete-conflicting-outputs

# Tests
flutter test

# Análisis
flutter analyze

# Formato
dart format .
```

---

## 📱 Build para Producción

### Android

```bash
# Build APK
flutter build apk --release \
  --dart-define=API_BASE_URL=https://cafeterianova.railway.app \
  --dart-define=ENVIRONMENT=production

# Build App Bundle (para Play Store)
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://cafeterianova.railway.app \
  --dart-define=ENVIRONMENT=production
```

### iOS

```bash
# Build IPA
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://cafeterianova.railway.app \
  --dart-define=ENVIRONMENT=production
```

---

## 🤖 Invocar Agente Especializado

Para diseño de nuevas features, arquitectura compleja o problemas de UX/accesibilidad, invoca:

**`flutter-architect`** — Ver `../.agents/AGENTES_README.md` para detalles

---

**Última actualización:** Julio 2025  
**Para contexto completo:** Ver `../.agents/CLAUDE.md`
