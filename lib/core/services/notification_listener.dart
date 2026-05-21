import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'websocket_service.dart';
import 'notification_service.dart';

/// Escucha eventos de WebSocket y dispara notificaciones locales.
///
/// Este listener se encarga de:
/// 1. Escuchar eventos de WebSocket en tiempo real
/// 2. Disparar notificaciones locales con sonido según el tipo de evento
/// 3. Filtrar eventos relevantes para el usuario actual
///
/// RF-054: Notificaciones push en cada cambio de estado del ciclo del pedido
/// RF-055: Sonido y vibración según configuración del dispositivo
/// RF-056: Notificaciones de rechazo con motivo y mensaje alentador
/// RF-057: Alerta visual y sonora en caja/cocina al llegar nuevo pedido
///
/// ⚠️ IMPORTANTE: Este listener recibe el Set _shownNotifications desde
/// NotificationController para EVITAR NOTIFICACIONES DUPLICADAS.
/// El WebSocket es el canal principal y el polling es el respaldo.
/// Ambos canales verifican el MISMO Set antes de disparar.
class NotificationListener {
  StreamSubscription<Map<String, dynamic>>? _orderCreatedSub;
  StreamSubscription<Map<String, dynamic>>? _orderAcceptedSub;
  StreamSubscription<Map<String, dynamic>>? _statusChangedSub;

  String? _currentUserId;
  String? _currentUserRole;
  bool _isListening = false;

  // Set COMPARTIDO con NotificationController para evitar duplicados
  // entre WebSocket (canal principal) y polling (fallback)
  // ⚠️ RECIBIDO desde NotificationController - NO crear instancia propia
  Set<String>? _sharedShownNotifications;

  /// Iniciar la escucha de eventos de WebSocket
  void startListening({
    required WebSocketService wsService,
    required NotificationService notificationService,
    required String currentUserId,
    required String currentUserRole,
    required Set<String> sharedShownNotifications,
  }) {
    _sharedShownNotifications = sharedShownNotifications;

    if (_isListening) return;

    _currentUserId = currentUserId;
    _currentUserRole = currentUserRole;
    _isListening = true;

    debugPrint('[NotificationListener] Iniciando escucha de eventos WebSocket...');

    // ──────────────────────────────────────────────
    // 1. Evento: Nuevo pedido creado (order:created)
    // ──────────────────────────────────────────────
    // RF-057: Alerta visual y sonora en caja/cocina al llegar nuevo pedido
    // RF-054: El cliente también recibe confirmación de su pedido
    _orderCreatedSub = wsService.onOrderCreated.listen((data) {
      if (!_isListening) return;

      // Extraer datos del pedido. El backend envía el objeto completo del pedido.
      // Los campos pueden estar en la raíz o anidados dentro de 'order'.
      final orderData = data['order'] as Map<String, dynamic>? ?? data;
      final orderId = data['orderId']?.toString() ?? orderData['_id']?.toString() ?? '';

      // Extraer userId desde el objeto del pedido para identificar al cliente
      final userId = data['userId']?.toString() ?? 
                     orderData['userId']?.toString() ?? 
                     orderData['userId']?._id?.toString() ?? '';

      // Extraer customerName desde customerSnapshot (estructura del backend)
      final customerSnapshot = orderData['customerSnapshot'] as Map<String, dynamic>?;
      final customerName = customerSnapshot?['firstName']?.toString() ?? data['customerName']?.toString() ?? 'Cliente';

      // Extraer amount desde totalAmount
      final amount = orderData['totalAmount']?.toString() ?? data['amount']?.toString() ?? '0';

      debugPrint('[NotificationListener] Evento order:created recibido: #$orderId '
          '(userId: $userId, cliente: $customerName, monto: \$$amount)');

      // Verificar deduplicación: evitar que el polling muestre la misma notificación
      final notifKey = '$orderId:CREADO';
      if (_sharedShownNotifications != null && _sharedShownNotifications!.contains(notifKey)) {
        debugPrint('[NotificationListener] ⏭ Notificación duplicada evitada: $notifKey');
        return;
      }
      _sharedShownNotifications?.add(notifKey);

      // NOTIFICAR AL CLIENTE que su pedido fue creado (RF-054)
      if (userId == currentUserId) {
        notificationService.showOrderCreatedNotification(orderId: orderId);
      }

      // NOTIFICAR A CAJA/ADMIN sobre nuevo pedido (RF-057)
      if (currentUserRole == 'cajero' || currentUserRole == 'admin') {
        notificationService.showNewOrderNotification(
          orderId: orderId,
          customerName: customerName,
          amount: amount,
        );
      }
    });


    // ──────────────────────────────────────────────
    // 2. Evento: Pedido aceptado (order:accepted)
    // ──────────────────────────────────────────────
    _orderAcceptedSub = wsService.onOrderAccepted.listen((data) {
      if (!_isListening) return;

      // Extraer datos del pedido. El backend envía el objeto completo del pedido.
      final orderData = data['order'] as Map<String, dynamic>? ?? data;
      final orderId = data['orderId']?.toString() ?? orderData['_id']?.toString() ?? '';

      // Extraer userId desde el objeto del pedido
      final userId = data['userId']?.toString() ?? orderData['userId']?.toString() ?? '';

      // Extraer customerName desde customerSnapshot (estructura del backend)
      final customerSnapshot = orderData['customerSnapshot'] as Map<String, dynamic>?;
      final customerName = customerSnapshot?['firstName']?.toString() ?? data['customerName']?.toString() ?? 'Cliente';

      debugPrint('[NotificationListener] Evento order:accepted recibido: #$orderId '
          '(userId: $userId, cliente: $customerName)');

      // Verificar deduplicación: evitar que el polling muestre la misma notificación
      final notifKey = '$orderId:ACEPTADO';
      if (_sharedShownNotifications != null && _sharedShownNotifications!.contains(notifKey)) {
        debugPrint('[NotificationListener] ⏭ Notificación duplicada evitada (accepted): $notifKey');
        return;
      }
      _sharedShownNotifications?.add(notifKey);

      // NOTIFICAR AL CLIENTE que su pedido fue aceptado (RF-054)
      if (userId == currentUserId) {
        notificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: '✅ Pedido Aceptado',
          body: 'Tu pedido ha sido aceptado. Pronto comenzará la preparación.',
          payload: orderId,
        );
      }

      // NOTIFICAR A COCINA que hay un nuevo pedido para preparar (RF-057)
      if (currentUserRole == 'cocina') {
        notificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: '👨‍🍳 Nuevo Pedido en Cocina',
          body: 'Preparar pedido de $customerName',
          payload: orderId,
        );
      }
    });

    // ──────────────────────────────────────────────
    // 3. Evento: Cambio de estado (status-changed)
    // ──────────────────────────────────────────────
    // RF-054: Notificaciones push en cada cambio de estado del ciclo del pedido
    _statusChangedSub = wsService.onStatusChanged.listen((data) {
      if (!_isListening) return;

      final orderId = data['orderId']?.toString() ?? '';
      final status = data['status']?.toString() ?? '';
      final userId = data['userId']?.toString() ?? '';
      final rejectionReason = data['rejectionReason']?.toString();
      final order = data['order'] as Map<String, dynamic>?;

      // Determinar el userId efectivo
      final effectiveUserId = userId.isNotEmpty
          ? userId
          : (order?['userId']?.toString() ?? '');

      final isMyOrder = effectiveUserId == currentUserId;

      debugPrint(
        '[NotificationListener] Evento status-changed: #$orderId → $status '
        '(userId: $effectiveUserId, isMyOrder: $isMyOrder, role: $currentUserRole)',
      );

      // Verificar deduplicación: evitar que el polling muestre la misma notificación
      final notifKey = '$orderId:$status';
      if (_sharedShownNotifications != null && _sharedShownNotifications!.contains(notifKey)) {
        debugPrint('[NotificationListener] ⏭ Notificación duplicada evitada (status-changed): $notifKey');
        return;
      }
      _sharedShownNotifications?.add(notifKey);

      switch (status) {
        case 'CREADO':
          // RF-054: Confirmación de pedido recibido (para el cliente)
          if (isMyOrder) {
            notificationService.showOrderCreatedNotification(orderId: orderId);
          }
          break;

        case 'PENDIENTE_EN_CAJA':
          // NOTIFICAR AL CLIENTE que su pedido está pendiente en caja (RF-054)
          if (isMyOrder) {
            notificationService.showNotification(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title: '📋 Pedido Pendiente',
              body: 'Tu pedido está en espera de confirmación por caja.',
              payload: orderId,
            );
          }
          // NOTIFICAR A CAJA/ADMIN sobre nuevo pedido (RF-057)
          if (currentUserRole == 'cajero' || currentUserRole == 'admin') {
            final customerName = order?['customerName']?.toString() ?? 'Cliente';
            final amount = order?['totalAmount']?.toString() ?? '0';
            notificationService.showNewOrderNotification(
              orderId: orderId,
              customerName: customerName,
              amount: amount,
            );
          }
          break;

        case 'ACEPTADO':
          // RF-054: Cliente recibe notificación cuando su pedido es aceptado
          if (isMyOrder) {
            notificationService.showNotification(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title: '✅ Pedido Aceptado',
              body: 'Tu pedido ha sido aceptado. Pronto comenzará la preparación.',
              payload: orderId,
            );
          }
          // NOTIFICAR A COCINA que hay un nuevo pedido para preparar (RF-057)
          if (currentUserRole == 'cocina') {
            final customerName = order?['customerName']?.toString() ?? 'Cliente';
            notificationService.showNotification(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title: '👨‍🍳 Nuevo Pedido en Cocina',
              body: 'Preparar pedido de $customerName',
              payload: orderId,
            );
          }
          break;

        case 'EN_PREPARACION':
          // RF-037: Cliente recibe notificación cuando su pedido está en preparación
          if (isMyOrder) {
            notificationService.showPreparingNotification(orderId: orderId);
          }
          // Notificar a caja que ya se está preparando
          if (currentUserRole == 'cajero' || currentUserRole == 'admin') {
            final customerName = order?['customerName']?.toString() ?? 'Cliente';
            notificationService.showNotification(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title: '👨‍🍳 Pedido en Preparación',
              body: 'Pedido de $customerName está siendo preparado',
              payload: orderId,
            );
          }
          break;

        case 'LISTO_PARA_ENTREGAR':
          // RF-040: Cliente recibe notificación cuando su pedido está listo
          // ⚠️ ESTA ES LA NOTIFICACIÓN MÁS IMPORTANTE DEL SISTEMA
          if (isMyOrder) {
            notificationService.showReadyNotification(orderId: orderId);
          }
          // También notificar a caja/admin que el pedido está listo
          if (currentUserRole == 'cajero' || currentUserRole == 'admin') {
            final customerName = order?['customerName']?.toString() ?? 'Cliente';
            notificationService.showNotification(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title: '✅ Pedido Listo para Entregar',
              body: 'Pedido de $customerName está listo',
              payload: orderId,
            );
          }
          break;

        case 'RECHAZADO_CAJA':
        case 'RECHAZADO_COCINA':
          // RF-056: Notificación de rechazo con motivo y mensaje alentador
          if (isMyOrder) {
            final reason = rejectionReason ?? 'No se especificó motivo';
            notificationService.showRejectedNotification(
              orderId: orderId,
              reason: reason,
            );
          }
          break;

        case 'ENTREGADO':
          // RF-041: Cliente recibe notificación de cierre
          if (isMyOrder) {
            notificationService.showDeliveredNotification(orderId: orderId);
          }
          break;
      }
    });

    debugPrint('[NotificationListener] Escucha de eventos WebSocket iniciada correctamente');
  }

  /// Detener todas las suscripciones
  void stopListening() {
    _isListening = false;
    _orderCreatedSub?.cancel();
    _orderCreatedSub = null;
    _orderAcceptedSub?.cancel();
    _orderAcceptedSub = null;
    _statusChangedSub?.cancel();
    _statusChangedSub = null;
    debugPrint('[NotificationListener] Escucha de eventos detenida');
  }

  /// Liberar recursos
  void dispose() {
    stopListening();
  }
}

/// Provider del listener de notificaciones
final notificationListenerProvider = Provider<NotificationListener>((ref) {
  final listener = NotificationListener();
  ref.onDispose(() => listener.dispose());
  return listener;
});
