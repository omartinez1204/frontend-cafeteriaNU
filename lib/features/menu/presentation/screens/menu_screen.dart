import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/product_model.dart';
import '../../../orders/presentation/providers/cart_provider.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../providers/menu_provider.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final notifier = ref.read(menuProvider.notifier);
      notifier.loadMenu();
      // Seleccionar categoría por defecto según la hora
      notifier.selectCategory(MenuState.defaultCategory);
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuProvider);
    final cartState = ref.watch(cartProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú'),
        actions: [
          // Badge del carrito
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => _navigateToCart(context),
              ),
              if (cartState.itemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: NovaColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cartState.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Categorías ──
          _CategoryBar(
            categories: menuState.categories,
            selected: menuState.selectedCategory,
            onSelected: (cat) => ref.read(menuProvider.notifier).selectCategory(cat),
          ),

          // ── Lista de productos ──
          Expanded(
            child: _buildContent(menuState, theme),
          ),
        ],
      ),
      // Botón flotante del carrito
      floatingActionButton: cartState.itemCount > 0
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToCart(context),
              backgroundColor: NovaColors.greenDark,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.shopping_cart),
              label: Text('\$${cartState.total.toStringAsFixed(2)}'),
            )
          : null,
    );
  }

  Widget _buildContent(MenuState state, ThemeData theme) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: NovaColors.error),
            const SizedBox(height: 16),
            Text(state.error!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(menuProvider.notifier).loadMenu(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final products = state.filteredProducts;
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: NovaColors.grayMedium),
            const SizedBox(height: 16),
            Text('No hay productos disponibles',
                style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(menuProvider.notifier).loadMenu(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _ProductCard(
            product: product,
            onAdd: () {
              // Validar límite de beca antes de agregar
              if (!_validateScholarshipLimit(context, ref, product)) return;

              if (product.availableRestrictions.isNotEmpty) {
                _showProductDetails(context, ref, product);
              } else {
                ref.read(cartProvider.notifier).addProduct(product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} agregado al carrito'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          ).animate().fadeIn(
                duration: 400.ms,
                delay: (index * 80).ms,
              ).slideX(begin: 0.05, end: 0);
        },
      ),
    );
  }

  void _navigateToCart(BuildContext context) {
    context.push('/cart');
  }

  /// Valida que un usuario con beca no agregue más de 1 producto
  /// de la categoría cubierta por su beca.
  /// Retorna true si se puede agregar, false si se debe bloquear.
  bool _validateScholarshipLimit(
      BuildContext context, WidgetRef ref, ProductModel product) {
    final authState = ref.read(authStateProvider);
    final cartState = ref.read(cartProvider);

    return authState.maybeWhen(
      authenticated: (user) {
        final scholarship = user.scholarship;
        final category = product.category;

        // Solo validar categorías cubiertas por beca
        final isCoveredCategory =
            (category == 'desayuno' && scholarship.hasDesayuno) ||
            (category == 'comida' && scholarship.hasComida);

        if (!isCoveredCategory) return true;

        // Verificar si ya tiene un producto de esa categoría en el carrito
        if (cartState.hasItemInCategory(category)) {
          final categoryLabel =
              category == 'desayuno' ? 'desayuno' : 'comida';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tu beca de $categoryLabel solo permite 1 producto de $categoryLabel. '
                'Ya tienes uno en tu carrito.',
              ),
              backgroundColor: NovaColors.warning,
              duration: const Duration(seconds: 3),
            ),
          );
          return false;
        }

        return true;
      },
      orElse: () => true,
    );
  }

  void _showProductDetails(
      BuildContext context, WidgetRef ref, ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProductDetailSheet(product: product),
    );
  }
}

class _ProductDetailSheet extends StatefulWidget {
  final ProductModel product;

  const _ProductDetailSheet({required this.product});

  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet> {
  final List<String> selectedRestrictions = [];
  final TextEditingController noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = widget.product;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NovaColors.grayLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            product.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: NovaColors.greenDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: NovaColors.grayMedium,
            ),
          ),
          const SizedBox(height: 24),
          if (product.availableRestrictions.isNotEmpty) ...[
            Text(
              '¿Alguna restricción?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: product.availableRestrictions.map((res) {
                final isSelected = selectedRestrictions.contains(res.name);
                return FilterChip(
                  label: Text(res.name),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        selectedRestrictions.add(res.name);
                      } else {
                        selectedRestrictions.remove(res.name);
                      }
                    });
                  },
                  selectedColor: NovaColors.greenDark,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : NovaColors.greenDark,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'Notas adicionales',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: noteController,
            decoration: InputDecoration(
              hintText: 'Ej: Sin servilletas, extra salsa...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: Consumer(
              builder: (context, ref, _) {
                // Verificar si la beca bloquea agregar este producto
                final authState = ref.watch(authStateProvider);
                final cartState = ref.watch(cartProvider);
                final isBlocked = authState.maybeWhen(
                  authenticated: (user) {
                    final scholarship = user.scholarship;
                    final cat = product.category;
                    final isCovered =
                        (cat == 'desayuno' && scholarship.hasDesayuno) ||
                        (cat == 'comida' && scholarship.hasComida);
                    return isCovered && cartState.hasItemInCategory(cat);
                  },
                  orElse: () => false,
                );

                return ElevatedButton(
                onPressed: isBlocked
                    ? null
                    : () {
                  ref.read(cartProvider.notifier).addProduct(
                        product,
                        restrictions: selectedRestrictions,
                        notes: noteController.text,
                      );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} agregado al carrito'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: NovaColors.greenDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Agregar al pedido',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Barra de categorías
class _CategoryBar extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryBar({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final categoryLabels = {
      'todas': 'Todas',
      'desayuno': 'Desayuno',
      'comida': 'Comida del Día',
      'antojitos': 'Antojitos',
      'especiales': 'Especiales',
    };

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selected;
          return FilterChip(
            label: Text(categoryLabels[cat] ?? cat),
            selected: isSelected,
            onSelected: (_) => onSelected(cat),
            selectedColor: NovaColors.greenDark,
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : NovaColors.greenDark,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          );
        },
      ),
    );
  }
}

/// Tarjeta de producto
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onAdd;

  const _ProductCard({required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Imagen placeholder
            // Imagen del producto (RF-017)
            Container(
              width: 72,
              height: 72,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: NovaColors.greenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: product.photoUrl != null
                  ? Image.network(
                      EnvConfig.getImageUrl(product.photoUrl)!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        _getCategoryIcon(product.category),
                        color: NovaColors.greenDark,
                        size: 32,
                      ),
                    )
                  : Icon(
                      _getCategoryIcon(product.category),
                      color: NovaColors.greenDark,
                      size: 32,
                    ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: NovaColors.greenDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: NovaColors.gold,
                        ),
                      ),
                      if (!product.isVisible)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: NovaColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Agotado',
                            style: TextStyle(
                              color: NovaColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Botón agregar
            IconButton(
              onPressed: product.isVisible ? onAdd : null,
              icon: Icon(
                product.availableRestrictions.isNotEmpty
                    ? Icons.tune_rounded
                    : Icons.add_circle_rounded,
                color: product.isVisible
                    ? NovaColors.greenDark
                    : NovaColors.grayMedium,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'desayuno':
        return Icons.coffee_rounded;
      case 'comida':
        return Icons.restaurant_rounded;
      case 'antojitos':
        return Icons.cookie_rounded;
      case 'especiales':
        return Icons.star_rounded;
      default:
        return Icons.restaurant_menu_rounded;
    }
  }
}
