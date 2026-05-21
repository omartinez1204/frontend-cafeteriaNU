import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'websocket_service.dart';
import 'notification_service.dart';
import 'notification_listener.dart';
import '../../features/orders/data/orders_repository.dart';
import '../../core/models/order_model.dart';

/// Controlador central de notificaciones que integra:
/// 1. WebSocket events (tiempo real) - canal PRINCIPAL
/// 2. Polling periódico (fallback cuando WebSocket falla)
/// 3. Detección de cambios de estado en pedidos
///
/// RF-054: Notificaciones push en cada cambio de estado del ciclo del pedido
/// RF-055: Sonido y vibración según configuración del dispositivo
/// RF-057: Alerta visual y sonora en caja/cocina al llegar nuevo pedido
///
/// ⚠️ IMPORTANTE: Para evitar NOTIFICACIONES DUPLICADAS, el polling SOLO
/// dispara notificaciones cuando detecta cambios que el WebSocket podría
/// haber perdido. El WebSocket es el canal principal y el polling es el
/// respaldo. Ambos canales comparten el mismo mapa _lastKnownStatuses
/// para evitar duplicados.
class NotificationController {
  final WebSocketService _wsService;
  final NotificationService _notificationService;
  final NotificationListener _notificationListener;
  final OrdersRepository _ordersRepository;

  String? _currentUserId;
  String? _currentUserRole;
  Timer? _pollingTimer;
  Timer? _dedupCleanupTimer;
  bool _isListening = false;

  // Mapa para rastrear el último estado conocido de cada pedido
  // orderId -> lastKnownStatus
  // COMPARTIDO entre WebSocket listener y polling para evitar duplicados
  final Map<String, String> _lastKnownStatuses = {};

  // Set para rastrear notificaciones ya mostradas (evita duplicados)
  // Formato: "orderId:status"
  // ⚠️ COMPARTIDO con NotificationListener para evitar duplicados entre
  // WebSocket (canal principal) y polling (fallback)
  final Set<String> _shownNotifications = {};

  NotificationController({
    required WebSocketService wsService,
    required NotificationService notificationService,
    required NotificationListener notificationListener,
    required OrdersRepository ordersRepository,
  })  : _wsService = wsService,
        _notificationService = notificationService,
        _notificationListener = notificationListener,
        _ordersRepository = ordersRepository;


  /// Iniciar el controlador de notificaciones
  void startListening({
    required String userId,
    required String userRole,
  }) {
    if (_isListening) return;

    _currentUserId = userId;
    _currentUserRole = userRole;
    _isListening = true;

    debugPrint('[NotificationController] Iniciando controlador de notificaciones...');

    // 1. Unirse a las salas WebSocket según el rol
    //    ⚠️ CRÍTICO: Esperar a que el WebSocket esté conectado antes de unirse a las salas
    //    Si el socket no está conectado, los emits se pierden.
    if (_wsService.isConnected) {
      _joinRooms(userRole);
    } else {
      // Si no está conectado, esperar a que se conecte
      debugPrint('[NotificationController] WebSocket no conectado, esperando conexión...');
      _wsService.connectionStatus.firstWhere((connected) => connected).then((_) {
        debugPrint('[NotificationController] WebSocket conectado, uniendo a salas...');
        _joinRooms(userRole);
      }).catchError((_) {
        debugPrint('[NotificationController] Error esperando conexión WebSocket');
      });
    }

    // 2. Iniciar el listener de WebSocket (tiempo real) - CANAL PRINCIPAL
    //    ⚠️ PASAR el Set _shownNotifications COMPARTIDO para evitar duplicados
    //    entre WebSocket (canal principal) y polling (fallback)
    _notificationListener.startListening(
      wsService: _wsService,
      notificationService: _notificationService,
      currentUserId: userId,
      currentUserRole: userRole,
      sharedShownNotifications: _shownNotifications,
    );


    // 3. Iniciar polling periódico como fallback (cada 5 segundos)
    //    RF-002: Las notificaciones deben entregarse en menos de 5 segundos
    _startPolling();

    // 4. Iniciar limpieza periodica del set de deduplicacion
    //    Evita que el set crezca sin limite y bloquee notificaciones legitimas
    _startDedupCleanup();

    debugPrint('[NotificationController] Controlador de notificaciones iniciado correctamente');
  }

  /// Unirse a las salas WebSocket según el rol del usuario
  void _joinRooms(String userRole) {
    if (userRole == 'cocina') {
      _wsService.joinKitchen();
      debugPrint('[NotificationController] Unido a sala: kitchen');
    }
    if (userRole == 'cajero' || userRole == 'admin') {
      _wsService.joinCashier();
      debugPrint('[NotificationController] Unido a sala: cashier');
    }
  }

  /// Iniciar polling periódico para detectar cambios de estado
  void _startPolling() {
    _pollingTimer?.cancel();

    // Polling cada 5 segundos para detectar cambios de estado
    // RF-002: Las notificaciones deben entregarse en menos de 5 segundos
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkForStatusChanges();
    });

    // ⚡ CRÍTICO: Hacer una primera ejecución INMEDIATA para precargar estados
    // Esto resuelve el bug donde el primer poll nunca detecta cambios porque
    // _lastKnownStatuses está vacío. Al precargar, el siguiente poll ya detectará
    // cualquier cambio real.
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkForStatusChanges(initialLoad: true);
    });

    debugPrint('[NotificationController] Polling de notificaciones iniciado (cada 5s)');
  }

  /// Verificar cambios de estado en los pedidos
  /// Para clientes: solo verifica sus propios pedidos
  /// Para cajero/admin/cocina: verifica TODOS los pedidos (nuevos, cambios de estado)
  ///
  /// [initialLoad]: si es true, solo precarga los estados sin disparar notificaciones
  Future<void> _checkForStatusChanges({bool initialLoad = false}) async {
    if (_currentUserId == null) return;

    try {
      final isStaff = _currentUserRole == 'cajero' ||
          _currentUserRole == 'admin' ||
          _currentUserRole == 'cocina';

      if (isStaff) {
        // ── Staff: Obtener pedidos activos (pendientes, en preparación, listos) ──
        // RF-057: Caja y cocina deben recibir alertas de nuevos pedidos
        final response = await _ordersRepository.getOrders(
          status: 'PENDIENTE_EN_CAJA,ACEPTADO,EN_PREPARACION,LISTO_PARA_ENTREGAR',
          limit: 50,
        );

        for (final order in response.orders) {
          final orderId = order.id;
          final currentStatus = order.currentStatus;
          final lastStatus = _lastKnownStatuses[orderId];

          if (lastStatus != null && lastStatus != currentStatus) {
            // ⚡ Cambio de estado detectado en un pedido que ya conocíamos
            // Solo notificar si el WebSocket no lo ha hecho ya (verificación de duplicados)
            final notifKey = '$orderId:$currentStatus';
            if (!_shownNotifications.contains(notifKey)) {
              debugPrint(
                '[NotificationController] Polling detectó cambio de estado: '
                '#$orderId: $lastStatus → $currentStatus',
              );
              _handleStaffStatusChange(order, currentStatus);
              _shownNotifications.add(notifKey);
            }
          } else if (lastStatus == null && !initialLoad) {
            // ⚡ NUEVO pedido detectado que no estaba en nuestro tracking
            final notifKey = '$orderId:$currentStatus';
            if (!_shownNotifications.contains(notifKey)) {
              debugPrint(
                '[NotificationController] Polling detectó NUEVO pedido: '
                '#$orderId (status: $currentStatus)',
              );
              _handleStaffStatusChange(order, currentStatus);
              _shownNotifications.add(notifKey);
            }
          }

          // Siempre actualizar el estado conocido
          _lastKnownStatuses[orderId] = currentStatus;
        }

        // Si es carga inicial y hay pedidos activos, trackearlos sin notificar
        if (initialLoad && response.orders.isNotEmpty) {
          debugPrint(
            '[NotificationController] Carga inicial completada: ${response.orders.length} pedidos activos trackeados',
          );
        }
      } else {
        // ── Cliente: Obtener solo sus propios pedidos ──
        final response = await _ordersRepository.getOrders(
          userId: _currentUserId,
          limit: 20,
        );

        for (final order in response.orders) {
          final orderId = order.id;
          final currentStatus = order.currentStatus;
          final lastStatus = _lastKnownStatuses[orderId];

          if (lastStatus != null && lastStatus != currentStatus) {
            // ⚡ Cambio de estado detectado en un pedido que ya conocíamos
            final notifKey = '$orderId:$currentStatus';
            if (!_shownNotifications.contains(notifKey)) {
              debugPrint(
                '[NotificationController] Polling detectó cambio de estado: '
                '#$orderId: $lastStatus → $currentStatus',
              );
              _handleStatusChange(order, currentStatus);
              _shownNotifications.add(notifKey);
            }
          } else if (lastStatus == null && !initialLoad) {
            // ⚡ NUEVO pedido detectado que no estaba en nuestro tracking
            final notifKey = '$orderId:$currentStatus';
            if (!_shownNotifications.contains(notifKey)) {
              debugPrint(
                '[NotificationController] Polling detectó NUEVO pedido propio: '
                '#$orderId (status: $currentStatus)',
              );
              _handleStatusChange(order, currentStatus);
              _shownNotifications.add(notifKey);
            }
          }

          // Siempre actualizar el estado conocido
          _lastKnownStatuses[orderId] = currentStatus;
        }

        // Si es carga inicial, precargar estados sin disparar notificaciones
        if (initialLoad && response.orders.isNotEmpty) {
          debugPrint(
            '[NotificationController] Carga inicial completada: ${response.orders.length} pedidos propios trackeados',
          );
        }
      }
    } catch (e) {
      // Silencioso - el polling no debe causar ruido en logs
    }
  }


  /// Manejar cambio de estado detectado por polling para staff (cajero/admin/cocina)
  void _handleStaffStatusChange(OrderModel order, String newStatus) {
    debugPrint('[NotificationController] POLLING staff: #${order.id} → $newStatus (role: $_currentUserRole)');
    final customerName = order.customerSnapshot?.firstName ?? 'Cliente';

    switch (newStatus) {
      case 'PENDIENTE_EN_CAJA':
        // RF-057: Nuevo pedido para caja
        if (_currentUserRole == 'cajero' || _currentUserRole == 'admin') {
          _notificationService.showNewOrderNotification(
            orderId: order.id,
            customerName: customerName,
            amount: order.totalAmount.toString(),
          );
        }
        break;

      case 'ACEPTADO':
        // RF-057: Nuevo pedido para cocina
        if (_currentUserRole == 'cocina') {
          _notificationService.showNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: '👨‍🍳 Nuevo Pedido en Cocina',
            body: 'Preparar pedido de $customerName',
            payload: order.id,
          );
        }
        break;

      case 'EN_PREPARACION':
        // Notificar a caja que ya se está preparando
        if (_currentUserRole == 'cajero' || _currentUserRole == 'admin') {
          _notificationService.showNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: '👨‍🍳 Pedido en Preparación',
            body: 'Pedido de $customerName está siendo preparado',
            payload: order.id,
          );
        }
        break;

      case 'LISTO_PARA_ENTREGAR':
        // RF-040: Notificar a caja que el pedido está listo
        if (_currentUserRole == 'cajero' || _currentUserRole == 'admin') {
          _notificationService.showNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: '✅ Pedido Listo para Entregar',
            body: 'Pedido de $customerName está listo',
            payload: order.id,
          );
        }
        break;

      case 'RECHAZADO_CAJA':
      case 'RECHAZADO_COCINA':
        if (_currentUserRole == 'cajero' || _currentUserRole == 'admin') {
          final reason = order.rejectionReason ?? 'Sin motivo especificado';
          _notificationService.showNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: '❌ Pedido Rechazado',
            body: 'Pedido de $customerName fue rechazado: $reason',
            payload: order.id,
          );
        }
        break;
    }
  }

  /// Manejar un cambio de estado detectado
  void _handleStatusChange(OrderModel order, String newStatus) {
    if (_currentUserId == null) return;

    debugPrint('[NotificationController] POLLING cliente: #${order.id} → $newStatus (isMyOrder: ${order.userId == _currentUserId})');

    final isMyOrder = order.userId == _currentUserId;

    switch (newStatus) {
      case 'CREADO':
        if (isMyOrder) {
          // RF-054: Confirmación de pedido recibido
          _notificationService.showOrderCreatedNotification(orderId: order.id);
        }
        break;

      case 'PENDIENTE_EN_CAJA':
        // RF-054: Cliente recibe notificación cuando su pedido está pendiente en caja
        if (isMyOrder) {
          _notificationService.showNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: '📋 Pedido Pendiente',
            body: 'Tu pedido está en espera de confirmación por caja.',
            payload: order.id,
          );
        }
        // Notificar a caja/admin sobre nuevo pedido
        if (_currentUserRole == 'cajero' || _currentUserRole == 'admin') {
          final customerName = order.customerSnapshot?.firstName ?? 'Cliente';
          _notificationService.showNewOrderNotification(
            orderId: order.id,
            customerName: customerName,
            amount: order.totalAmount.toString(),
          );
        }
        break;

      case 'ACEPTADO':
        if (isMyOrder) {
          // RF-054: Cliente recibe notificación cuando su pedido es aceptado
          _notificationService.showNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: '✅ Pedido Aceptado',
            body: 'Tu pedido ha sido aceptado. Pronto comenzará la preparación.',
            payload: order.id,
          );
        }
        // Notificar a cocina sobre nuevo pedido para preparar
        if (_currentUserRole == 'cocina') {
          final customerName = order.customerSnapshot?.firstName ?? 'Cliente';
          _notificationService.showNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: '👨‍🍳 Nuevo Pedido en Cocina',
            body: 'Preparar pedido de $customerName',
            payload: order.id,
          );
        }
        break;

      case 'EN_PREPARACION':
        if (isMyOrder) {
          _notificationService.showPreparingNotification(orderId: order.id);
        }
        // Notificar a caja que ya se está preparando
        if (_currentUserRole == 'cajero' || _currentUserRole == 'admin') {
          final customerName = order.customerSnapshot?.firstName ?? 'Cliente';
          _notificationService.showNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: '👨‍🍳 Pedido en Preparación',
            body: 'Pedido de $customerName está siendo preparado',
            payload: order.id,
          );
        }
        break;

      case 'LISTO_PARA_ENTREGAR':
        if (isMyOrder) {
          // Esta es la notificación MÁS IMPORTANTE - con sonido fuerte
          _notificationService.showReadyNotification(orderId: order.id);
        }
        // Notificar a caja que el pedido está listo
        if (_currentUserRole == 'cajero' || _currentUserRole == 'admin') {
          final customerName = order.customerSnapshot?.firstName ?? 'Cliente';
          _notificationService.showNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: '✅ Pedido Listo para Entregar',
            body: 'Pedido de $customerName está listo',
            payload: order.id,
          );
        }
        break;

      case 'RECHAZADO_CAJA':
      case 'RECHAZADO_COCINA':
        if (isMyOrder) {
          final reason = order.rejectionReason ?? 'No se especificó motivo';
          _notificationService.showRejectedNotification(
            orderId: order.id,
            reason: reason,
          );
        }
        break;

      case 'ENTREGADO':
        if (isMyOrder) {
          _notificationService.showDeliveredNotification(orderId: order.id);
        }
        break;
    }
  }

  /// Registrar un pedido para seguimiento de cambios de estado
  void trackOrder(OrderModel order) {
    _lastKnownStatuses[order.id] = order.currentStatus;
  }

  /// Registrar múltiples pedidos para seguimiento
  void trackOrders(List<OrderModel> orders) {
    for (final order in orders) {
      _lastKnownStatuses[order.id] = order.currentStatus;
    }
  }

  /// Detener todas las suscripciones
  void stopListening() {
    _isListening = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _dedupCleanupTimer?.cancel();
    _dedupCleanupTimer = null;
    _notificationListener.stopListening();
    _lastKnownStatuses.clear();
    _shownNotifications.clear();
    debugPrint('[NotificationController] Controlador de notificaciones detenido');
  }

  /// Limpiar el set de deduplicacion cada 30 minutos para evitar
  /// que crezca sin limite y bloquee notificaciones legitimas.
  void _startDedupCleanup() {
    _dedupCleanupTimer?.cancel();
    _dedupCleanupTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      if (_shownNotifications.length > 200) {
        final entriesToKeep = _shownNotifications.take(100).toSet();
        final removed = _shownNotifications.length - entriesToKeep.length;
        _shownNotifications
          ..clear()
          ..addAll(entriesToKeep);
        debugPrint(
          '[NotificationController] Dedup cleanup: removidas $removed entradas antiguas',
        );
      }
    });
  }

  /// Liberar recursos
  void dispose() {
    stopListening();
  }
}

/// Provider del controlador de notificaciones
/// Usamos Provider.family para tener una instancia por userId,
/// pero nos aseguramos de que se limpie correctamente al cambiar de usuario.
final notificationControllerProvider = Provider.family<NotificationController, String>(
  (ref, userId) {
    final wsService = ref.watch(webSocketServiceProvider);
    final notificationService = ref.watch(notificationServiceProvider);
    final notificationListener = ref.watch(notificationListenerProvider);
    final ordersRepository = ref.watch(ordersRepositoryProvider);

    final controller = NotificationController(
      wsService: wsService,
      notificationService: notificationService,
      notificationListener: notificationListener,
      ordersRepository: ordersRepository,
    );

    ref.onDispose(() => controller.dispose());
    return controller;
  },
);
