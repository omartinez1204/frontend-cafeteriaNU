import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/product_model.dart';
import '../../data/menu_repository.dart';

/// Estado del menú
class MenuState {
  final List<ProductModel> products;
  final bool isLoading;
  final String? error;
  final String selectedCategory;

  const MenuState({
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategory = 'todas',
  });

  /// Determina la categoría por defecto según la hora del día
  static String get defaultCategory {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final totalMinutes = hour * 60 + minute;

    const breakfastStart = 7 * 60 + 20; // 7:20 AM
    const lunchStart = 13 * 60; // 1:00 PM
    const lunchEnd = 15 * 60 + 30; // 3:30 PM

    if (totalMinutes >= breakfastStart && totalMinutes < lunchStart) {
      return 'desayuno';
    } else if (totalMinutes >= lunchStart && totalMinutes <= lunchEnd) {
      return 'comida';
    }
    return 'todas';
  }

  List<ProductModel> get filteredProducts {
    // El backend ya filtra por horario y visibilidad en /products/menu.
    // El frontend solo aplica el filtro de categoria seleccionada por el usuario.
    if (selectedCategory == 'todas') return products;

    return products.where((p) => p.category == selectedCategory).toList();
  }

  List<String> get categories {
    final cats = products.map((p) => p.category).toSet();

    final now = DateTime.now();
    final totalMinutes = now.hour * 60 + now.minute;

    // Horarios en minutos
    const breakfastStart = 7 * 60 + 20; // 7:20 AM
    const lunchStart = 13 * 60;          // 1:00 PM

    final isBreakfastTime =
        totalMinutes >= breakfastStart && totalMinutes < lunchStart;

    // Orden fijo: [desayuno|comida] → antojitos → especiales → todas
    // Si es horario de desayuno, desayuno va primero; de lo contrario, comida.
    final List<String> orderedCategories = [];

    if (isBreakfastTime) {
      if (cats.contains('desayuno')) orderedCategories.add('desayuno');
      if (cats.contains('comida')) orderedCategories.add('comida');
    } else {
      if (cats.contains('comida')) orderedCategories.add('comida');
      if (cats.contains('desayuno')) orderedCategories.add('desayuno');
    }

    if (cats.contains('antojitos')) orderedCategories.add('antojitos');
    if (cats.contains('especiales')) orderedCategories.add('especiales');

    // Cualquier otra categoría no contemplada
    for (final cat in cats) {
      if (!orderedCategories.contains(cat)) orderedCategories.add(cat);
    }

    // 'todas' siempre al final
    orderedCategories.add('todas');

    return orderedCategories;
  }

  MenuState copyWith({
    List<ProductModel>? products,
    bool? isLoading,
    String? error,
    String? selectedCategory,
  }) {
    return MenuState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

/// Notifier del menú
class MenuNotifier extends StateNotifier<MenuState> {
  final MenuRepository _repository;

  MenuNotifier(this._repository) : super(const MenuState());

  /// Cargar el menú
  Future<void> loadMenu() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final products = await _repository.getMenu();
      state = state.copyWith(products: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar el menú: $e',
      );
    }
  }

  /// Cambiar categoría seleccionada
  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  /// Limpiar error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider del menú
final menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  final repository = ref.watch(menuRepositoryProvider);
  return MenuNotifier(repository);
});
