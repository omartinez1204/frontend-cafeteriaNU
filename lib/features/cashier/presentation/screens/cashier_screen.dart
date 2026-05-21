import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../../core/models/order_model.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';

class CashierScreen extends ConsumerStatefulWidget {
  const CashierScreen({super.key});

  @override
  ConsumerState<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends ConsumerState<CashierScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      // Cargar todos los pedidos recientes para que ambos providers se llenen
      ref.read(ordersProvider.notifier).loadOrders();
      ref.read(webSocketServiceProvider).joinCashier();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingState = ref.watch(pendingOrdersProvider);
    final readyState = ref.watch(readyOrdersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caja'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_rounded),
            tooltip: 'Cambiar Tema',
            onPressed: () => _showThemeBottomSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar pedidos',
            onPressed: () => ref.read(ordersProvider.notifier).loadOrders(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: NovaColors.gold,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Nuevos (Caja)'),
                  if (pendingState.orders.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: NovaColors.gold,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${pendingState.orders.length}',
                        style: const TextStyle(
                          color: NovaColors.greenDark,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Para Entregar'),
                  if (readyState.orders.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: NovaColors.greenDark,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${readyState.orders.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContent(pendingState, theme, isPendingTab: true),
          _buildContent(readyState, theme, isPendingTab: false),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // El cajero navega al menú para crear pedido manual
          context.push('/menu');
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Pedido Manual'),
        backgroundColor: NovaColors.greenDark,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildContent(OrdersState state, ThemeData theme, {required bool isPendingTab}) {
    if (state.isLoading && state.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: NovaColors.error),
            const SizedBox(height: 16),
            Text(state.error!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(ordersProvider.notifier).loadOrders(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPendingTab ? Icons.check_circle_outline : Icons.inventory_2_outlined,
              size: 80,
              color: NovaColors.grayMedium,
            ),
            const SizedBox(height: 16),
            Text(
              isPendingTab ? 'No hay pedidos nuevos' : 'No hay pedidos listos',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(ordersProvider.notifier).loadOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80), // bottom padding for FAB
        itemCount: state.orders.length,
        itemBuilder: (context, index) {
          final order = state.orders[index];
          return _CashierOrderCard(order: order, isPendingTab: isPendingTab)
              .animate()
              .fadeIn(duration: 300.ms, delay: (index * 50).ms)
              .slideY(begin: 0.05, end: 0);
        },
      ),
    );
  }

  void _showThemeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final activeTheme = ref.watch(themeProvider);
            final themeNotifier = ref.read(themeProvider.notifier);
            final theme = Theme.of(context);

            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personalizar Tema',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _themeBottomSheetOption(
                        style: AppThemeStyle.light,
                        label: 'Claro',
                        primaryColor: const Color(0xFF1A4731),
                        activeTheme: activeTheme,
                        onTap: () {
                          themeNotifier.setTheme(AppThemeStyle.light);
                          Navigator.of(ctx).pop();
                        },
                      ),
                      _themeBottomSheetOption(
                        style: AppThemeStyle.dark,
                        label: 'Oscuro',
                        primaryColor: const Color(0xFF2E7D52),
                        activeTheme: activeTheme,
                        onTap: () {
                          themeNotifier.setTheme(AppThemeStyle.dark);
                          Navigator.of(ctx).pop();
                        },
                      ),
                      _themeBottomSheetOption(
                        style: AppThemeStyle.pink,
                        label: 'Rosa',
                        primaryColor: const Color(0xFFD81B60),
                        activeTheme: activeTheme,
                        onTap: () {
                          themeNotifier.setTheme(AppThemeStyle.pink);
                          Navigator.of(ctx).pop();
                        },
                      ),
                      _themeBottomSheetOption(
                        style: AppThemeStyle.purple,
                        label: 'Púrpura',
                        primaryColor: const Color(0xFFAB47BC),
                        activeTheme: activeTheme,
                        onTap: () {
                          themeNotifier.setTheme(AppThemeStyle.purple);
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _themeBottomSheetOption({
    required AppThemeStyle style,
    required String label,
    required Color primaryColor,
    required AppThemeStyle activeTheme,
    required VoidCallback onTap,
  }) {
    final isSelected = activeTheme == style;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.amber : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _CashierOrderCard extends ConsumerWidget {
  final OrderModel order;
  final bool isPendingTab;

  const _CashierOrderCard({required this.order, required this.isPendingTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Datos del Cliente
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: NovaColors.greenLight,
                  child: order.customerSnapshot?.photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            EnvConfig.getImageUrl(order.customerSnapshot!.photoUrl!)!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.person, color: NovaColors.greenDark),
                          ),
                        )
                      : const Icon(Icons.person, color: NovaColors.greenDark),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerSnapshot?.fullName ?? 'Cliente',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'PEDIDO #${order.id.substring(order.id.length - 6)}',
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge de beca
                    if (order.paymentMethod == 'beca')
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: NovaColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school_rounded, size: 14, color: NovaColors.gold),
                            SizedBox(width: 4),
                            Text(
                              'Beca',
                              style: TextStyle(
                                color: NovaColors.gold,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPendingTab
                            ? NovaColors.gold.withValues(alpha: 0.15)
                            : NovaColors.greenDark.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPendingTab ? 'Nuevo' : 'Listo',
                        style: TextStyle(
                          color: isPendingTab ? NovaColors.gold : NovaColors.greenDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            // Items
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: NovaColors.greenLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: NovaColors.greenDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.productSnapshot.name,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '\$${item.subtotal.toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )),
            const Divider(height: 16),
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  '\$${order.totalAmount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: NovaColors.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Actions
            if (isPendingTab)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref.read(ordersProvider.notifier).acceptOrder(order.id);
                        },
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Aceptar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NovaColors.greenDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () => _showRejectDialog(context, ref, order.id),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Rechazar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: NovaColors.error,
                          side: const BorderSide(color: NovaColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(ordersProvider.notifier).deliverOrder(order.id);
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(order.paymentMethod == 'beca' ? 'Entregar (Beca)' : 'Cobrar y Entregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NovaColors.greenDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref, String orderId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar Pedido'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Motivo del rechazo',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(ordersProvider.notifier).rejectCashier(orderId, controller.text);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }
}
