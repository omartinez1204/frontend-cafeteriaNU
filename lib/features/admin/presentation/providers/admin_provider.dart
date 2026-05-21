import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_repository.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/services/websocket_service.dart';

class AdminState {
  final List<UserModel> pendingUsers;
  final List<UserModel> allUsers;
  final List<ProductModel> products;
  final List<RestrictionModel> restrictions;
  final bool isLoading;
  final String? error;

  AdminState({
    this.pendingUsers = const [],
    this.allUsers = const [],
    this.products = const [],
    this.restrictions = const [],
    this.isLoading = false,
    this.error,
  });

  AdminState copyWith({
    List<UserModel>? pendingUsers,
    List<UserModel>? allUsers,
    List<ProductModel>? products,
    List<RestrictionModel>? restrictions,
    bool? isLoading,
    String? error,
  }) {
    return AdminState(
      pendingUsers: pendingUsers ?? this.pendingUsers,
      allUsers: allUsers ?? this.allUsers,
      products: products ?? this.products,
      restrictions: restrictions ?? this.restrictions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  final AdminRepository _repository;
  final WebSocketService _wsService;
  StreamSubscription<Map<String, dynamic>>? _userRegisteredSub;

  AdminNotifier(this._repository, this._wsService) : super(AdminState()) {
    _initWebSocketListener();
  }

  void _initWebSocketListener() {
    _userRegisteredSub = _wsService.onUserRegistered.listen((data) {
      debugPrint('[AdminNotifier] Nuevo usuario registrado: ${data['email']}');
      // Recargar usuarios pendientes inmediatamente
      loadPendingUsers();
      loadAllUsers();
    });
  }

  Future<void> loadPendingUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await _repository.getPendingUsers();
      state = state.copyWith(pendingUsers: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadAllUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await _repository.getAllUsers();
      state = state.copyWith(allUsers: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> approveUser(String userId) async {
    try {
      await _repository.approveUser(userId);
      await loadPendingUsers();
      await loadAllUsers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateScholarship(String userId, Map<String, bool> scholarship) async {
    try {
      await _repository.updateScholarship(userId, scholarship);
      await loadAllUsers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _repository.deleteUser(userId);
      await loadAllUsers();
      await loadPendingUsers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // --- Productos ---
  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final products = await _repository.getAllProducts();
      state = state.copyWith(products: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createProduct(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.createProduct(data);
      await loadProducts();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.updateProduct(id, data);
      await loadProducts();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _repository.deleteProduct(id);
      await loadProducts();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // --- Restricciones ---
  Future<void> loadRestrictions() async {
    try {
      final restrictions = await _repository.getAllRestrictions();
      state = state.copyWith(restrictions: restrictions);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> createRestriction(String name) async {
    try {
      await _repository.createRestriction(name);
      await loadRestrictions();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteRestriction(String id) async {
    try {
      await _repository.deleteRestriction(id);
      await loadRestrictions();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // --- Imagenes ---
  Future<String?> uploadImage(String filePath) async {
    try {
      return await _repository.uploadImage(filePath);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  final wsService = ref.watch(webSocketServiceProvider);
  return AdminNotifier(repository, wsService);
});
