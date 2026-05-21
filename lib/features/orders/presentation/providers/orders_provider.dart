import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/orders_repository.dart';
import '../../../../core/models/order_model.dart';
import '../../../../core/services/websocket_service.dart';

/// Estado de los pedidos
class OrdersState {
  final List<OrderModel> orders;
  final bool isLoading;
  final String? error;
  final int totalPages;
  final int currentPage;

  const OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.totalPages = 0,
    this.currentPage = 1,
  });

  OrdersState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    String? error,
    int? totalPages,
    int? currentPage,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Notifier de pedidos
class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrdersRepository _repository;
  final WebSocketService _wsService;
  StreamSubscription<Map<String, dynamic>>? _orderCreatedSub;
  StreamSubscription<Map<String, dynamic>>? _orderAcceptedSub;
  StreamSubscription<Map<String, dynamic>>? _statusChangedSub;
  bool _disposed = false;

  OrdersNotifier(this._repository, this._wsService) : super(const OrdersState()) {
    _initWebSocketListeners();
  }

  void _initWebSocketListeners() {
    // Escuchar nuevos pedidos (para caja)
    _orderCreatedSub = _wsService.onOrderCreated.listen((data) {
      final order = OrderModel.fromJson(data);
      _addOrUpdateOrder(order);
    });

    // Escuchar pedidos aceptados (para cocina)
    _orderAcceptedSub = _wsService.onOrderAccepted.listen((data) {
      final order = OrderModel.fromJson(data);
      _addOrUpdateOrder(order);
    });

    // Escuchar cambios de estado
    _statusChangedSub = _wsService.onStatusChanged.listen((data) {
      // El backend envía { orderId, status, timestamp, order?: fullOrderObject }
      // Si viene el objeto completo 'order', lo usamos directamente
      if (data.containsKey('order') && data['order'] != null) {
        final order = OrderModel.fromJson(data['order'] as Map<String, dynamic>);
        _addOrUpdateOrder(order);
      } else if (data.containsKey('orderId')) {
        // Si solo viene el orderId, refrescamos ese pedido desde el backend
        final orderId = data['orderId'] as String;
        _repository.getById(orderId).then((order) {
          _addOrUpdateOrder(order);
        }).catchError((_) {
          // Si falla la carga individual, recargamos toda la lista
          loadOrders();
        });
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _orderCreatedSub?.cancel();
    _orderAcceptedSub?.cancel();
    _statusChangedSub?.cancel();
    super.dispose();
  }

  void _addOrUpdateOrder(OrderModel order) {
    if (_disposed) return;
    final index = state.orders.indexWhere((o) => o.id == order.id);
    if (index >= 0) {
      final updatedList = [...state.orders];
      updatedList[index] = order;
      state = state.copyWith(orders: updatedList);
    } else {
      state = state.copyWith(orders: [order, ...state.orders]);
    }
  }

  /// Crear un nuevo pedido
  Future<OrderModel> create({
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    String? customerNote,
    String? scholarshipUserId,
  }) async {
    try {
      final order = await _repository.create(
        items: items,
        paymentMethod: paymentMethod,
        customerNote: customerNote,
        scholarshipUserId: scholarshipUserId,
      );

      // Unirse a la sala del pedido INMEDIATAMENTE despues de obtener el ID
      // para no perder los eventos WebSocket subsecuentes (Bug 3a fix).
      // Los eventos iniciales (CREADO, PENDIENTE_EN_CAJA) se emitieron durante
      // la llamada API, pero los siguientes (ACEPTADO, EN_PREPARACION, LISTO)
      // seran recibidos porque el cliente ya esta en la sala order:{id}.
      _wsService.joinOrder(order.id);
      debugPrint('[OrdersNotifier] Cliente unido a sala: order:${order.id}');

      _addOrUpdateOrder(order);

      return order;
    } catch (e) {
      state = state.copyWith(error: 'Error al crear pedido: $e');
      rethrow;
    }
  }

  /// Cargar pedidos (con filtro opcional por estado)
  Future<void> loadOrders({String? status, String? userId, int page = 1}) async {

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.getOrders(
        status: status,
        userId: userId,
        page: page,
      );
      state = state.copyWith(
        orders: response.orders,
        isLoading: false,
        totalPages: response.totalPages,
        currentPage: page,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar pedidos: $e',
      );
    }
  }

  /// Aceptar pedido (cajero/admin)
  Future<OrderModel?> acceptOrder(String id) async {
    try {
      final order = await _repository.accept(id);
      _updateOrderInList(order);
      return order;
    } catch (e) {
      state = state.copyWith(error: 'Error al aceptar pedido: $e');
      return null;
    }
  }

  /// Rechazar pedido en caja
  Future<OrderModel?> rejectCashier(String id, String reason) async {
    try {
      final order = await _repository.rejectCashier(id, reason);
      _updateOrderInList(order);
      return order;
    } catch (e) {
      state = state.copyWith(error: 'Error al rechazar pedido: $e');
      return null;
    }
  }

  /// Iniciar preparación (cocina)
  Future<OrderModel?> startPreparation(String id) async {
    try {
      final order = await _repository.startPreparation(id);
      _updateOrderInList(order);
      return order;
    } catch (e) {
      state = state.copyWith(error: 'Error al iniciar preparación: $e');
      return null;
    }
  }

  /// Rechazar pedido en cocina
  Future<OrderModel?> rejectKitchen(String id, String reason) async {
    try {
      final order = await _repository.rejectKitchen(id, reason);
      _updateOrderInList(order);
      return order;
    } catch (e) {
      state = state.copyWith(error: 'Error al rechazar pedido: $e');
      return null;
    }
  }

  /// Marcar como listo (cocina)
  Future<OrderModel?> markReady(String id) async {
    try {
      final order = await _repository.markReady(id);
      _updateOrderInList(order);
      return order;
    } catch (e) {
      state = state.copyWith(error: 'Error al marcar listo: $e');
      return null;
    }
  }

  /// Entregar pedido (cajero/admin)
  Future<OrderModel?> deliverOrder(String id) async {
    try {
      final order = await _repository.deliver(id);
      _updateOrderInList(order);
      return order;
    } catch (e) {
      state = state.copyWith(error: 'Error al entregar pedido: $e');
      return null;
    }
  }

  /// Actualizar un pedido en la lista local
  void _updateOrderInList(OrderModel updatedOrder) {
    if (_disposed) return;
    final index = state.orders.indexWhere((o) => o.id == updatedOrder.id);
    if (index >= 0) {
      final updatedList = [...state.orders];
      updatedList[index] = updatedOrder;
      state = state.copyWith(orders: updatedList);
    }
  }

  /// Actualizar pedido desde WebSocket
  void updateFromWebSocket(OrderModel order) {
    _updateOrderInList(order);
  }

  /// Limpiar error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider de pedidos
final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  final repository = ref.watch(ordersRepositoryProvider);
  final wsService = ref.watch(webSocketServiceProvider);
  return OrdersNotifier(repository, wsService);
});

/// Provider para pedidos pendientes (caja)
final pendingOrdersProvider = Provider<OrdersState>((ref) {
  final ordersState = ref.watch(ordersProvider);
  final pending = ordersState.orders
      .where((o) => o.currentStatus == 'PENDIENTE_EN_CAJA' || o.currentStatus == 'CREADO')
      .toList();
  return ordersState.copyWith(orders: pending);
});

/// Provider para pedidos listos para entregar (caja)
final readyOrdersProvider = Provider<OrdersState>((ref) {
  final ordersState = ref.watch(ordersProvider);
  final ready = ordersState.orders
      .where((o) => o.currentStatus == 'LISTO_PARA_ENTREGAR')
      .toList();
  return ordersState.copyWith(orders: ready);
});

/// Provider para pedidos en preparación (cocina)
final kitchenOrdersProvider = Provider<OrdersState>((ref) {
  final ordersState = ref.watch(ordersProvider);
  final kitchen = ordersState.orders
      .where((o) =>
          o.currentStatus == 'PENDIENTE_EN_CAJA' ||
          o.currentStatus == 'ACEPTADO' ||
          o.currentStatus == 'EN_PREPARACION' ||
          o.currentStatus == 'LISTO_PARA_ENTREGAR')
      .toList();
  return ordersState.copyWith(orders: kitchen);
});
