import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/user_model.dart';
import '../providers/cart_provider.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';


class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);

    // Obtener beca del usuario
    UserScholarship? scholarship;
    authState.maybeWhen(
      authenticated: (user) => scholarship = user.scholarship,
      orElse: () {},
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito'),
        actions: [
          if (!cartState.isEmpty)
            TextButton(
              onPressed: () => _showClearDialog(context, ref),
              child: const Text('Vaciar'),
            ),
        ],
      ),
      body: cartState.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: NovaColors.grayMedium),
                  const SizedBox(height: 16),
                  Text('Tu carrito está vacío',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Ir al menú'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartState.items.length,
                    itemBuilder: (context, index) {
                      final item = cartState.items[index];

                      // Verificar si este item está limitado por beca
                      final cat = item.product.category;
                      final isScholarshipItem = scholarship != null &&
                          ((cat == 'desayuno' && scholarship!.hasDesayuno) ||
                           (cat == 'comida' && scholarship!.hasComida));
                      // Un item de beca no puede tener cantidad > 1
                      final isQuantityLocked = isScholarshipItem && item.quantity >= 1;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Info del producto
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    if (item.restrictions.isNotEmpty)
                                      Text(
                                        item.restrictions.join(', '),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: NovaColors.greenDark,
                                          fontSize: 10,
                                        ),
                                      ),
                                    if (isScholarshipItem)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: NovaColors.gold.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          '🎓 Beca · Máx. 1',
                                          style: TextStyle(
                                            color: NovaColors.gold,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${item.product.price.toStringAsFixed(2)} c/u',
                                      style: const TextStyle(
                                          color: NovaColors.gold,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              // Control de cantidad
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () {
                                      ref
                                          .read(cartProvider.notifier)
                                          .updateQuantity(
                                              index, item.quantity - 1);
                                    },
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.add_circle_outline,
                                      color: isQuantityLocked
                                          ? NovaColors.grayMedium
                                          : null,
                                    ),
                                    onPressed: isQuantityLocked
                                        ? null
                                        : () {
                                      ref
                                          .read(cartProvider.notifier)
                                          .updateQuantity(
                                              index, item.quantity + 1);
                                    },
                                  ),
                                ],
                              ),
                              // Subtotal
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '\$${item.subtotal.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: NovaColors.greenDark,
                                  ),
                                ),
                              ),
                              // Eliminar
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    color: NovaColors.error),
                                onPressed: () {
                                  ref
                                      .read(cartProvider.notifier)
                                      .removeItem(index);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // ── Resumen ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total',
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            Text(
                              '\$${cartState.total.toStringAsFixed(2)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: NovaColors.gold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () =>
                                _navigateToCheckout(context, ref),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: NovaColors.greenDark,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Continuar',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showClearDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text('¿Estás seguro de vaciar el carrito?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clear();
              Navigator.of(ctx).pop();
            },
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
  }

  void _navigateToCheckout(BuildContext context, WidgetRef ref) {
    context.push('/checkout');
  }
}
