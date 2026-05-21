import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env_config.dart';

/// Servicio WebSocket para comunicación en tiempo real con el backend
class WebSocketService {
  IO.Socket? _socket;
  bool _isConnected = false;
  final _statusController = StreamController<bool>.broadcast();
  final _orderCreatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _orderAcceptedController = StreamController<Map<String, dynamic>>.broadcast();
  final _statusChangedController = StreamController<Map<String, dynamic>>.broadcast();
  final _userRegisteredController = StreamController<Map<String, dynamic>>.broadcast();

  // Salas a las que el cliente se ha unido (para re-unir en reconexión)
  final Set<String> _joinedRooms = {};
  final List<String> _joinedOrderIds = [];

  /// Stream de estado de conexión
  Stream<bool> get connectionStatus => _statusController.stream;
  Stream<Map<String, dynamic>> get onOrderCreated => _orderCreatedController.stream;
  Stream<Map<String, dynamic>> get onOrderAccepted => _orderAcceptedController.stream;
  Stream<Map<String, dynamic>> get onStatusChanged => _statusChangedController.stream;
  Stream<Map<String, dynamic>> get onUserRegistered => _userRegisteredController.stream;

  bool get isConnected => _isConnected;

  /// Conectar al WebSocket
  void connect({String? token}) {
    if (_isConnected) return;

    final uri = EnvConfig.wsUrl;
    _socket = IO.io(
      uri,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({
            if (token != null) 'Authorization': 'Bearer $token',
          })
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      _statusController.add(true);
      print('[WS] Conectado a $uri');
      // Re-unir a todas las salas previas (las membresias se pierden en reconexion)
      _rejoinRooms();
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _statusController.add(false);
      print('[WS] Desconectado');
    });

    _socket!.onConnectError((data) {
      print('[WS] Error de conexión: $data');
    });

    // Eventos del negocio
    _socket!.on('order:created', (data) {
      _orderCreatedController.add(data as Map<String, dynamic>);
    });

    _socket!.on('order:accepted', (data) {
      _orderAcceptedController.add(data as Map<String, dynamic>);
    });

    _socket!.on('order:status-changed', (data) {
      _statusChangedController.add(data as Map<String, dynamic>);
    });

    _socket!.on('user:registered', (data) {
      _userRegisteredController.add(data as Map<String, dynamic>);
    });

    _socket!.connect();
  }

  /// Unirse a una sala (con tracking para reconexion)
  void joinKitchen() {
    _joinedRooms.add('kitchen');
    _socket?.emit('join-kitchen');
  }
  void joinCashier() {
    _joinedRooms.add('cashier');
    _socket?.emit('join-cashier');
  }
  void joinOrder(String orderId) {
    if (!_joinedOrderIds.contains(orderId)) {
      _joinedOrderIds.add(orderId);
    }
    _socket?.emit('join-order', orderId);
  }
  void joinAdmin() {
    _joinedRooms.add('admin');
    _socket?.emit('join-admin');
  }

  /// Re-unir a todas las salas previamente unidas tras una reconexion
  void _rejoinRooms() {
    for (final room in _joinedRooms) {
      _socket?.emit('join-$room');
      print('[WS] Re-unido a sala: $room');
    }
    for (final orderId in _joinedOrderIds) {
      _socket?.emit('join-order', orderId);
      print('[WS] Re-unido a sala: order:$orderId');
    }
  }

  /// Desconectar
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  /// Liberar recursos
  void dispose() {
    disconnect();
    _joinedRooms.clear();
    _joinedOrderIds.clear();
    _statusController.close();
    _orderCreatedController.close();
    _orderAcceptedController.close();
    _statusChangedController.close();
    _userRegisteredController.close();
  }
}

/// Provider del WebSocket
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});
