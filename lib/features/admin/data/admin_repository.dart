import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/providers/dio_provider.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return AdminRepository(dio);
});

class AdminRepository {
  final Dio _dio;

  AdminRepository(this._dio);

  Future<List<UserModel>> getPendingUsers() async {
    final response = await _dio.get('/users/pending');
    final data = _unwrapData(response.data);
    return (data as List).map((e) => UserModel.fromJson(e)).toList();
  }

  Future<void> approveUser(String userId) async {
    await _dio.patch('/users/$userId/approve');
  }

  Future<void> toggleUserActive(String userId, bool isActive) async {
    await _dio.patch('/users/$userId/active', data: {'isActive': isActive});
  }

  Future<List<UserModel>> getAllUsers() async {
    final response = await _dio.get('/users');
    final data = _unwrapData(response.data);
    return (data as List).map((e) => UserModel.fromJson(e)).toList();
  }

  Future<void> updateScholarship(String userId, Map<String, bool> scholarship) async {
    await _dio.patch('/users/$userId/scholarship', data: {'scholarship': scholarship});
  }

  Future<void> deleteUser(String userId) async {
    await _dio.delete('/users/$userId');
  }

  Future<void> updateMpConfig(Map<String, String> config) async {
    // Placeholder para configuración de Mercado Pago
    // await _dio.patch('/admin/settings/mp', data: config);
  }

  // --- Gestión de Productos ---
  Future<List<ProductModel>> getAllProducts() async {
    final response = await _dio.get('/products?all=true');
    final data = _unwrapData(response.data);
    return (data as List).map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<ProductModel> createProduct(Map<String, dynamic> data) async {
    final response = await _dio.post('/products', data: data);
    return ProductModel.fromJson(_unwrapData(response.data));
  }

  Future<ProductModel> updateProduct(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/products/$id', data: data);
    return ProductModel.fromJson(_unwrapData(response.data));
  }

  Future<void> deleteProduct(String id) async {
    await _dio.delete('/products/$id');
  }

  // --- Gestión de Restricciones ---
  Future<List<RestrictionModel>> getAllRestrictions() async {
    final response = await _dio.get('/restrictions');
    final data = _unwrapData(response.data);
    return (data as List).map((e) => RestrictionModel.fromJson(e)).toList();
  }

  Future<RestrictionModel> createRestriction(String name) async {
    final response = await _dio.post('/restrictions', data: {'name': name});
    return RestrictionModel.fromJson(_unwrapData(response.data));
  }

  Future<void> deleteRestriction(String id) async {
    await _dio.delete('/restrictions/$id');
  }

  // --- Carga de Imágenes ---
  Future<String> uploadImage(String filePath) async {
    final fileName = filePath.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await _dio.post(
      '/uploads/image',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _unwrapData(response.data)['url'];
  }

  dynamic _unwrapData(dynamic responseData) {
    if (responseData is Map && responseData['data'] != null) {
      return responseData['data'];
    }
    return responseData;
  }
}
