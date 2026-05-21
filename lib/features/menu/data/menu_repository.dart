import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/product_model.dart';
import '../../../core/providers/dio_provider.dart';

/// Provider del repositorio de menú
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return MenuRepository(dioClient.dio);
});

class MenuRepository {
  final Dio _dio;

  MenuRepository(this._dio);

  /// Obtener todos los productos del menú (filtrado por tiempo en el servidor)
  Future<List<ProductModel>> getMenu() async {
    final response = await _dio.get('/products/menu');
    final data = _unwrapData(response.data);
    debugPrint('[MenuRepository] /products/menu → type=${data.runtimeType}, '
        'isList=${data is List}, length=${data is List ? data.length : 'N/A'}');
    if (data is List) {
      final products = data
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
      debugPrint('[MenuRepository] Productos parseados: ${products.length}');
      for (final p in products) {
        debugPrint('[MenuRepository]   - ${p.name} (${p.category}) visible=${p.isVisible}');
      }
      return products;
    }
    debugPrint('[MenuRepository] ⚠️ Respuesta inesperada: $data');
    return [];
  }

  /// Obtener productos por categoría
  Future<List<ProductModel>> getByCategory(String category) async {
    final response = await _dio.get('/products', queryParameters: {'category': category});
    final data = _unwrapData(response.data);
    if (data is List) {
      return data.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Obtener un producto por ID
  Future<ProductModel> getById(String id) async {
    final response = await _dio.get('/products/$id');
    final data = _unwrapData(response.data);
    return ProductModel.fromJson(data as Map<String, dynamic>);
  }

  /// Extraer data del wrapper { success, data }
  dynamic _unwrapData(dynamic responseData) {
    if (responseData is Map && responseData['data'] != null) {
      return responseData['data'];
    }
    return responseData;
  }
}
