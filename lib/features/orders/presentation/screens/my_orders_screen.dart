import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/order_model.dart';
import '../providers/orders_provider.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(ordersProvider.notifier).loadOrders());
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    final theme = Theme.of(context);

    // Separar pedidos activos e históricos
    final activeOrders = ordersState.orders.where((o) => 
      o.currentStatus != 'ENTREGADO' && 
      o.currentStatus != 'RECHAZADO_CAJA' && 
      o.currentStatus != 'RECHAZADO_COCINA'
    ).toList();

    final historyOrders = ordersState.orders.where((o) => 
      o.currentStatus == 'ENTREGADO' || 
      o.currentStatus == 'RECHAZADO_CAJA' || 
      o.currentStatus == 'RECHAZADO_COCINA'
    ).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Pedidos'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Activos', icon: Icon(Icons.pending_actions_rounded)),
              Tab(text: 'Historial', icon: Icon(Icons.history_rounded)),
            ],
            indicatorColor: NovaColors.gold,
            labelColor: NovaColors.gold,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrderList(activeOrders, ordersState, theme, 'No tienes pedidos activos'),
            _buildOrderList(historyOrders, ordersState, theme, 'Tu historial está vacío'),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders, OrdersState state, ThemeData theme, String emptyMessage) {
    if (state.isLoading && orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: NovaColors.error),
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

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: NovaColors.grayMedium),
            const SizedBox(height: 16),
            Text(emptyMessage, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.pushReplacement('/home'),
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(ordersProvider.notifier).loadOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _OrderCard(order: order)
              .animate()
              .fadeIn(duration: 300.ms, delay: (index * 100).ms)
              .slideX(begin: 0.05, end: 0);
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pedido #${order.id.substring(0, 8)}',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                _StatusBadge(status: order.currentStatus),
              ],
            ),
            // Mostrar motivo de rechazo si el pedido fue rechazado
            if ((order.currentStatus == 'RECHAZADO_CAJA' ||
                    order.currentStatus == 'RECHAZADO_COCINA') &&
                order.rejectionReason != null &&
                order.rejectionReason!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: NovaColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: NovaColors.error.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    'Motivo: ${order.rejectionReason}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: NovaColors.error,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            // Items
            ...order.items.take(3).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text('${item.quantity}x ',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: NovaColors.greenDark)),
                      Expanded(
                        child: Text(item.productSnapshot.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                )),
            if (order.items.length > 3)
              Text('...and ${order.items.length - 3} more',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: NovaColors.grayMedium)),
            const Divider(height: 16),
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(order.createdAt),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: NovaColors.grayMedium),
                ),
                Text(
                  '\$${order.totalAmount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: NovaColors.gold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'CREADO':
      case 'PENDIENTE_EN_CAJA':
        return _StatusConfig('Pendiente', NovaColors.gold);
      case 'ACEPTADO':
        return _StatusConfig('Aceptado', Colors.blue);
      case 'EN_PREPARACION':
        return _StatusConfig('Preparando', Colors.orange);
      case 'LISTO_PARA_ENTREGAR':
        return _StatusConfig('Listo', NovaColors.greenDark);
      case 'ENTREGADO':
        return _StatusConfig('Entregado', NovaColors.greenDark);
      case 'RECHAZADO_CAJA':
      case 'RECHAZADO_COCINA':
        return _StatusConfig('Rechazado', NovaColors.error);
      default:
        return _StatusConfig(status, NovaColors.grayMedium);
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  const _StatusConfig(this.label, this.color);
}
