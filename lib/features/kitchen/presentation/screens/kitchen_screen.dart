import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/models/order_model.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../orders/presentation/providers/orders_provider.dart';

class KitchenScreen extends ConsumerStatefulWidget {
  const KitchenScreen({super.key});

  @override
  ConsumerState<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends ConsumerState<KitchenScreen> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ordersProvider.notifier).loadOrders(
        status: 'PENDIENTE_EN_CAJA,ACEPTADO,EN_PREPARACION,LISTO_PARA_ENTREGAR',
      );
      ref.read(webSocketServiceProvider).joinKitchen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final kitchenState = ref.watch(kitchenOrdersProvider);
    final theme = Theme.of(context);

    // Pedidos pendientes y en proceso
    final kitchenOrders = kitchenState.orders
        .where((o) => o.currentStatus == 'PENDIENTE_EN_CAJA' ||
            o.currentStatus == 'ACEPTADO' ||
            o.currentStatus == 'EN_PREPARACION' ||
            o.currentStatus == 'LISTO_PARA_ENTREGAR')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cocina'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_rounded),
            tooltip: 'Cambiar Tema',
            onPressed: () => _showThemeBottomSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(ordersProvider.notifier).loadOrders(
              status: 'PENDIENTE_EN_CAJA,ACEPTADO,EN_PREPARACION,LISTO_PARA_ENTREGAR',
            ),
          ),
        ],
      ),
      body: _buildContent(kitchenOrders, kitchenState, theme),
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

  Widget _buildContent(List<OrderModel> orders, OrdersState state, ThemeData theme) {
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
              onPressed: () =>
                  ref.read(ordersProvider.notifier).loadOrders(),
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
            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: NovaColors.grayMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay pedidos en cocina',
              style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Los pedidos pendientes y aceptados aparecerán aquí',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: NovaColors.grayMedium)),
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
          return _KitchenOrderCard(
            key: ValueKey(order.id),
            order: order,
          );
        },
      ),
    );
  }
}

class _KitchenOrderCard extends ConsumerWidget {
  final OrderModel order;

  const _KitchenOrderCard({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPending = order.currentStatus == 'PENDIENTE_EN_CAJA';
    final isAccepted = order.currentStatus == 'ACEPTADO';
    final isPreparing = order.currentStatus == 'EN_PREPARACION';
    final isReady = order.currentStatus == 'LISTO_PARA_ENTREGAR';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            // Header: Foto y Datos del Cliente (RF-038)
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
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
                const SizedBox(width: 12),
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
                        order.customerSnapshot?.area.toUpperCase() ?? 'ÁREA',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: NovaColors.greenDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 10),
                      ),
                    ],
                  ),
                ),
                 _KitchenStatusBadge(status: order.currentStatus),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pedido #${order.id.substring(order.id.length - 6)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: NovaColors.grayMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Items
             ...order.items.map((item) => Padding(
                   padding: const EdgeInsets.only(bottom: 4),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
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
                         ],
                       ),
                       if (item.restrictions.isNotEmpty)
                         Padding(
                           padding: const EdgeInsets.only(left: 36, top: 2),
                           child: Text(
                             item.restrictions.join(', '),
                             style: theme.textTheme.bodySmall?.copyWith(
                               color: NovaColors.error,
                               fontWeight: FontWeight.bold,
                               fontSize: 10,
                             ),
                           ),
                         ),
                     ],
                   ),
                 )),
            const SizedBox(height: 8),
             // Notas
             if (order.customerNote != null && order.customerNote!.isNotEmpty)
               Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: NovaColors.gold.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: Row(
                   children: [
                     Icon(Icons.notes_rounded,
                         size: 16, color: NovaColors.gold),
                     const SizedBox(width: 8),
                     Expanded(
                       child: Text(
                         order.customerNote!,
                         style: theme.textTheme.bodySmall,
                       ),
                     ),
                   ],
                 ),
               ),
            const SizedBox(height: 12),
             // Actions
             Row(
               children: [
                 if (isPending)
                   Expanded(
                     child: _ActionButton(
                       label: 'Aceptar',
                       icon: Icons.check_circle_rounded,
                       color: NovaColors.greenDark,
                       onPressed: () {
                         ref.read(ordersProvider.notifier).acceptOrder(order.id);
                       },
                     ),
                   ),
                 if (isAccepted)
                   Expanded(
                     child: _ActionButton(
                       label: 'Iniciar Preparación',
                       icon: Icons.play_arrow_rounded,
                       color: Colors.orange,
                       onPressed: () {
                         ref.read(ordersProvider.notifier).startPreparation(order.id);
                       },
                     ),
                   ),
                 if (isPreparing)
                   Expanded(
                     child: _ActionButton(
                       label: 'Marcar Listo',
                       icon: Icons.check_circle_rounded,
                       color: NovaColors.greenDark,
                       onPressed: () {
                         ref.read(ordersProvider.notifier).markReady(order.id);
                       },
                     ),
                   ),
                 if (isReady)
                   Expanded(
                     child: Container(
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(
                         color: NovaColors.greenDark.withValues(alpha: 0.1),
                         borderRadius: BorderRadius.circular(8),
                       ),
                       child: const Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Icon(Icons.check_circle,
                               color: NovaColors.greenDark, size: 20),
                           SizedBox(width: 8),
                           Text(
                             'Esperando entrega',
                             style: TextStyle(
                               fontWeight: FontWeight.bold,
                               color: NovaColors.greenDark,
                             ),
                           ),
                         ],
                       ),
                     ),
                   ),
                 if (isPending || isPreparing)
                   const SizedBox(width: 8),
                 if (isPending || isPreparing)
                   Expanded(
                     child: _ActionButton(
                       label: 'Rechazar',
                       icon: Icons.close_rounded,
                       color: NovaColors.error,
                       onPressed: () => _showRejectDialog(context, ref, order.id),
                     ),
                   ),
               ],
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
                ref.read(ordersProvider.notifier).rejectKitchen(orderId, controller.text);
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _KitchenStatusBadge extends StatelessWidget {
  final String status;

  const _KitchenStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.color),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _KitchenStatusConfig _getConfig(String status) {
    switch (status) {
      case 'ACEPTADO':
        return _KitchenStatusConfig(
            'Pendiente', Colors.blue, Icons.hourglass_empty);
      case 'EN_PREPARACION':
        return _KitchenStatusConfig(
            'Preparando', Colors.orange, Icons.restaurant_rounded);

      case 'LISTO_PARA_ENTREGAR':
        return _KitchenStatusConfig(
            'Listo', NovaColors.greenDark, Icons.check_circle);
      default:
        return _KitchenStatusConfig(
            status, NovaColors.grayMedium, Icons.circle);
    }
  }
}

class _KitchenStatusConfig {
  final String label;
  final Color color;
  final IconData icon;
  const _KitchenStatusConfig(this.label, this.color, this.icon);
}
