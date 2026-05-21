import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/order_model.dart';
import '../../../core/providers/dio_provider.dart';

/// Provider del repositorio de pedidos
final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return OrdersRepository(dioClient.dio);
});

class OrdersRepository {
  final Dio _dio;

  OrdersRepository(this._dio);

  /// Crear un nuevo pedido
  Future<OrderModel> create({
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    String? customerNote,
    String? scholarshipUserId,
  }) async {
    final body = <String, dynamic>{
      'items': items,
      'paymentMethod': paymentMethod,
      'customerNote': customerNote,
    };
    if (scholarshipUserId != null) {
      body['scholarshipUserId'] = scholarshipUserId;
    }
    final response = await _dio.post('/orders', data: body);
    final data = _unwrapData(response.data);
    return OrderModel.fromJson(data as Map<String, dynamic>);
  }

  /// Obtener pedidos (con filtros opcionales)
  Future<OrdersResponse> getOrders({
    String? status,
    String? userId,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) query['status'] = status;
    if (userId != null) query['userId'] = userId;

    final response = await _dio.get('/orders', queryParameters: query);
    final data = _unwrapData(response.data);
    return OrdersResponse.fromJson(data as Map<String, dynamic>);
  }

  /// Obtener un pedido por ID
  Future<OrderModel> getById(String id) async {
    final response = await _dio.get('/orders/$id');
    final data = _unwrapData(response.data);
    return OrderModel.fromJson(data as Map<String, dynamic>);
  }

  /// Aceptar pedido (cajero/admin)
  Future<OrderModel> accept(String id) async {
    final response = await _dio.patch('/orders/$id/accept');
    final data = _unwrapData(response.data);
    return OrderModel.fromJson(data as Map<String, dynamic>);
  }

  /// Rechazar pedido en caja (cajero/admin)
  Future<OrderModel> rejectCashier(String id, String reason) async {
    final response = await _dio.patch('/orders/$id/reject-cashier', data: {
      'rejectionReason': reason,
    });
    final data = _unwrapData(response.data);
    return OrderModel.fromJson(data as Map<String, dynamic>);
  }

  /// Iniciar preparación (cocina)
  Future<OrderModel> startPreparation(String id) async {
    final response = await _dio.patch('/orders/$id/start-preparation');
    final data = _unwrapData(response.data);
    return OrderModel.fromJson(data as Map<String, dynamic>);
  }

  /// Rechazar pedido en cocina (cocina)
  Future<OrderModel> rejectKitchen(String id, String reason) async {
    final response = await _dio.patch('/orders/$id/reject-kitchen', data: {
      'rejectionReason': reason,
    });
    final data = _unwrapData(response.data);
    return OrderModel.fromJson(data as Map<String, dynamic>);
  }

  /// Marcar como listo (cocina)
  Future<OrderModel> markReady(String id) async {
    final response = await _dio.patch('/orders/$id/ready');
    final data = _unwrapData(response.data);
    return OrderModel.fromJson(data as Map<String, dynamic>);
  }

  /// Entregar pedido (cajero/admin)
  Future<OrderModel> deliver(String id) async {
    final response = await _dio.patch('/orders/$id/deliver');
    final data = _unwrapData(response.data);
    return OrderModel.fromJson(data as Map<String, dynamic>);
  }

  /// Extraer data del wrapper { success, data }
  dynamic _unwrapData(dynamic responseData) {
    if (responseData is Map && responseData['data'] != null) {
      return responseData['data'];
    }
    return responseData;
  }
}

/// Respuesta paginada de pedidos
class OrdersResponse {
  final List<OrderModel> orders;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  OrdersResponse({
    required this.orders,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory OrdersResponse.fromJson(Map<String, dynamic> json) {
    final ordersList = json['data'] as List? ?? [];
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return OrdersResponse(
      orders: ordersList
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (meta['total'] as num?)?.toInt() ?? 0,
      page: (meta['page'] as num?)?.toInt() ?? 1,
      limit: (meta['limit'] as num?)?.toInt() ?? 20,
      totalPages: (meta['totalPages'] as num?)?.toInt() ?? 0,
    );
  }
}
