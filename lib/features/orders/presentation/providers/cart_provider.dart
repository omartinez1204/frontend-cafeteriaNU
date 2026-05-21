import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/product_model.dart';


/// Item en el carrito
class CartItem {
  final ProductModel product;
  int quantity;
  final List<String> restrictions;
  final String? notes;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.restrictions = const [],
    this.notes,
  });

  double get subtotal => product.price * quantity;

  Map<String, dynamic> toOrderItem() => {
        'productId': product.id,
        'quantity': quantity,
        'restrictions': restrictions,
      };
}

/// Estado del carrito
class CartState {
  final List<CartItem> items;
  final String? generalNotes;

  const CartState({
    this.items = const [],
    this.generalNotes,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  double get total => items.fold(0.0, (sum, item) => sum + item.subtotal);
  bool get isEmpty => items.isEmpty;

  /// Verifica si ya hay un producto de la categoría dada en el carrito.
  bool hasItemInCategory(String category) {
    return items.any((item) => item.product.category == category);
  }

  /// Retorna la cantidad total de items de una categoría en el carrito.
  int categoryItemCount(String category) {
    return items
        .where((item) => item.product.category == category)
        .fold(0, (sum, item) => sum + item.quantity);
  }

  CartState copyWith({
    List<CartItem>? items,
    String? generalNotes,
  }) {
    return CartState(
      items: items ?? this.items,
      generalNotes: generalNotes ?? this.generalNotes,
    );
  }
}

/// Notifier del carrito
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  /// Agregar producto al carrito
  void addProduct(ProductModel product, {int quantity = 1, List<String>? restrictions, String? notes}) {
    final existingIndex = state.items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      // Ya existe, incrementar cantidad
      final updatedItems = [...state.items];
      updatedItems[existingIndex] = CartItem(
        product: updatedItems[existingIndex].product,
        quantity: updatedItems[existingIndex].quantity + quantity,
        restrictions: restrictions ?? updatedItems[existingIndex].restrictions,
        notes: notes ?? updatedItems[existingIndex].notes,
      );
      state = state.copyWith(items: updatedItems);
    } else {
      state = state.copyWith(
        items: [
          ...state.items,
          CartItem(
            product: product,
            quantity: quantity,
            restrictions: restrictions ?? [],
            notes: notes,
          ),
        ],
      );
    }
  }

  /// Actualizar cantidad de un producto
  void updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      removeItem(index);
      return;
    }
    final updatedItems = [...state.items];
    updatedItems[index] = CartItem(
      product: updatedItems[index].product,
      quantity: quantity,
      restrictions: updatedItems[index].restrictions,
      notes: updatedItems[index].notes,
    );
    state = state.copyWith(items: updatedItems);
  }

  /// Eliminar un item del carrito
  void removeItem(int index) {
    final updatedItems = [...state.items]..removeAt(index);
    state = state.copyWith(items: updatedItems);
  }

  /// Limpiar carrito
  void clear() {
    state = const CartState();
  }

  /// Establecer notas generales
  void setNotes(String notes) {
    state = state.copyWith(generalNotes: notes);
  }

  /// Obtener items formateados para la API
  List<Map<String, dynamic>> getOrderItems() {
    return state.items.map((item) => item.toOrderItem()).toList();
  }
}

/// Provider del carrito
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
