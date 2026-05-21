import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/services/websocket_service.dart';
import '../providers/admin_provider.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../../core/models/user_model.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _restrictionController = TextEditingController();
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    Future.microtask(() {
      ref.read(adminProvider.notifier).loadPendingUsers();
      ref.read(adminProvider.notifier).loadAllUsers();
      ref.read(ordersProvider.notifier).loadOrders(status: 'PENDIENTE_EN_CAJA');
      ref.read(adminProvider.notifier).loadProducts();
      ref.read(adminProvider.notifier).loadRestrictions();
      // Unirse a la sala admin para recibir eventos WebSocket en tiempo real
      ref.read(webSocketServiceProvider).joinAdmin();
    });

    // Polling de respaldo cada 15s para usuarios pendientes
    // (por si el WebSocket falla o se desconecta)
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        ref.read(adminProvider.notifier).loadPendingUsers();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.dispose();
    _restrictionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final theme = Theme.of(context);
    final pendingOrders = ref.watch(pendingOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white, // Color para la pestaña activa
          unselectedLabelColor: Colors.white.withValues(
            alpha: 0.6,
          ), // Color para pestañas inactivas
          indicatorColor: NovaColors.gold, // Indicador dorado para contraste
          tabs: const [
            Tab(icon: Icon(Icons.person_add_rounded), text: 'Nuevos'),
            Tab(icon: Icon(Icons.people_rounded), text: 'Usuarios'),
            Tab(icon: Icon(Icons.payments_rounded), text: 'Caja'),
            Tab(icon: Icon(Icons.restaurant_menu_rounded), text: 'Menú'),
            Tab(icon: Icon(Icons.block_rounded), text: 'Restricciones'),
          ],
        ),
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
            onPressed: () {
              ref.read(adminProvider.notifier).loadPendingUsers();
              ref.read(adminProvider.notifier).loadAllUsers();
              ref.read(ordersProvider.notifier).loadOrders();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingTab(state, theme),
          _buildAllUsersTab(state, theme),
          _buildCajaTab(pendingOrders, theme),
          _buildMenuTab(state, theme),
          _buildRestrictionsTab(state, theme),
        ],
      ),
    );
  }

  Widget _buildCajaTab(OrdersState state, ThemeData theme) {
    if (state.isLoading && state.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.orders.isEmpty)
      return _buildEmptyState('No hay pedidos en caja', theme);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.orders.length,
      itemBuilder: (context, index) {
        final order = state.orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pedido #${order.id.substring(order.id.length - 6)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildStatusBadge(order.currentStatus),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Cliente: ${order.customerSnapshot?.fullName ?? "Desconocido"}',
                ),
                Text(
                  'Área: ${order.customerSnapshot?.area.toUpperCase() ?? "N/A"}',
                ),
                const Divider(),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• ${item.quantity}x ${item.productSnapshot.name} (\$${item.productSnapshot.price})',
                    ),
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: \$${order.totalAmount}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: NovaColors.error,
                          ),
                          onPressed: () => _showRejectDialog(context, order.id),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.check,
                            color: NovaColors.greenDark,
                          ),
                          onPressed: () => ref
                              .read(ordersProvider.notifier)
                              .acceptOrder(order.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRejectDialog(BuildContext context, String orderId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar Pedido'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Motivo del rechazo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(ordersProvider.notifier)
                    .rejectCashier(orderId, controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status == 'CREADO' ? Colors.blue : Colors.orange,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPendingTab(AdminState state, ThemeData theme) {
    if (state.isLoading && state.pendingUsers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) return _buildErrorState(state.error!, theme);
    if (state.pendingUsers.isEmpty)
      return _buildEmptyState('No hay registros pendientes', theme);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(adminProvider.notifier).loadPendingUsers();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.pendingUsers.length,
        itemBuilder: (context, index) {
          final user = state.pendingUsers[index];
          return _PendingUserCard(
            user: user,
            onApprove: () => _confirmApproval(context, user.id, user.fullName),
            onReject: () => _confirmRejectUser(context, user.id, user.fullName),
          );
        },
      ),
    );
  }

  Widget _buildAllUsersTab(AdminState state, ThemeData theme) {
    if (state.isLoading && state.allUsers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.allUsers.isEmpty)
      return _buildEmptyState('No hay usuarios registrados', theme);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(adminProvider.notifier).loadAllUsers();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.allUsers.length,
        itemBuilder: (context, index) {
          final user = state.allUsers[index];
          return _UserCard(
            user: user,
            actionLabel: 'Gestionar',
            onAction: () => _showUserManagementDialog(context, user),
            roleColor: user.role == 'admin'
                ? NovaColors.gold
                : NovaColors.grayMedium,
            showScholarshipInfo: true,
          );
        },
      ),
    );
  }

  Widget _buildMenuTab(AdminState state, ThemeData theme) {
    if (state.isLoading && state.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Gestión de Productos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showProductForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NovaColors.greenDark,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(100, 40),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.products.length,
            itemBuilder: (context, index) {
              final product = state.products[index];
              return _ProductListTile(
                product: product,
                onEdit: () => _showProductForm(context, product: product),
                onDelete: () => _confirmDeleteProduct(context, product),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showProductForm(BuildContext context, {ProductModel? product}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ProductFormDialog(product: product),
    );
  }

  void _confirmDeleteProduct(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text(
          '¿Estás seguro de eliminar "${product.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(adminProvider.notifier).deleteProduct(product.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: NovaColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildRestrictionsTab(AdminState state, ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Gestión de Restricciones',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Formulario para crear nueva restricción
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _restrictionController,
                  decoration: const InputDecoration(
                    hintText: 'Nueva restricción (ej: sin mayonesa)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (value) => _createRestriction(value),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: ElevatedButton(
                  onPressed: () =>
                      _createRestriction(_restrictionController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NovaColors.greenDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  child: const Text('Agregar'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: state.restrictions.isEmpty
              ? _buildEmptyState('No hay restricciones configuradas', theme)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.restrictions.length,
                  itemBuilder: (context, index) {
                    final restriction = state.restrictions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(
                          Icons.block_rounded,
                          color: NovaColors.error,
                        ),
                        title: Text(
                          restriction.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_rounded,
                            color: NovaColors.error,
                          ),
                          onPressed: () =>
                              _confirmDeleteRestriction(context, restriction),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _createRestriction(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    ref.read(adminProvider.notifier).createRestriction(trimmed);
    _restrictionController.clear();
  }

  void _confirmDeleteRestriction(
    BuildContext context,
    RestrictionModel restriction,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Restricción'),
        content: Text(
          '¿Estás seguro de eliminar "${restriction.name}"?\n\nEsta restricción se eliminará de todos los productos que la usen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(adminProvider.notifier)
                  .deleteRestriction(restriction.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: NovaColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: NovaColors.error),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center),
          TextButton(
            onPressed: () =>
                ref.read(adminProvider.notifier).loadPendingUsers(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inbox_rounded,
            size: 48,
            color: NovaColors.grayMedium,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: NovaColors.grayMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmApproval(BuildContext context, String userId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Aprobación'),
        content: Text('¿Deseas activar la cuenta de $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(adminProvider.notifier).approveUser(userId);
              Navigator.pop(ctx);
            },
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
  }

  void _showUserManagementDialog(BuildContext context, UserModel user) {
    final currentUser = ref
        .read(authStateProvider)
        .maybeWhen(authenticated: (u) => u, orElse: () => null);
    final isCurrentUser = currentUser?.id == user.id;
    final canHaveScholarship = ![
      'admin',
      'cocina',
      'cajero',
    ].contains(user.role);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isCurrentUser)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_rounded,
                      color: NovaColors.error,
                    ),
                    tooltip: 'Eliminar usuario',
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDeleteUser(context, user);
                    },
                  ),
              ],
            ),
            Text(
              user.email,
              style: const TextStyle(color: NovaColors.grayMedium),
            ),
            if (canHaveScholarship) ...[
              const Divider(height: 32),
              const Text(
                'Becas de Alimentos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              StatefulBuilder(
                builder: (context, setModalState) {
                  return Column(
                    children: [
                      CheckboxListTile(
                        title: const Text('Beca Desayuno'),
                        value: user.scholarship.hasDesayuno,
                        activeColor: NovaColors.greenDark,
                        onChanged: (val) async {
                          await ref
                              .read(adminProvider.notifier)
                              .updateScholarship(user.id, {
                                'hasDesayuno': val ?? false,
                                'hasComida': user.scholarship.hasComida,
                              });
                          if (context.mounted) Navigator.pop(ctx);
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Beca Comida'),
                        value: user.scholarship.hasComida,
                        activeColor: NovaColors.greenDark,
                        onChanged: (val) async {
                          await ref
                              .read(adminProvider.notifier)
                              .updateScholarship(user.id, {
                                'hasDesayuno': user.scholarship.hasDesayuno,
                                'hasComida': val ?? false,
                              });
                          if (context.mounted) Navigator.pop(ctx);
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text(
          '¿Estás seguro de eliminar a "${user.fullName}"?\n\nEsta acción eliminará permanentemente al usuario y no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(adminProvider.notifier).deleteUser(user.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: NovaColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _confirmRejectUser(BuildContext context, String userId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar Registro'),
        content: Text(
          '¿Estás seguro de rechazar y eliminar el registro de "$name"?\n\nEl usuario será eliminado permanentemente y deberá registrarse de nuevo si desea intentarlo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(adminProvider.notifier).deleteUser(userId);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: NovaColors.error),
            child: const Text('Rechazar'),
          ),
        ],
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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

class _PendingUserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingUserCard({
    required this.user,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: NovaColors.greenLight,
          child: Text(
            user.profile.firstName[0],
            style: const TextStyle(color: NovaColors.greenDark),
          ),
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${user.email}\n${user.profile.area.toUpperCase()}'),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 72,
              height: 32,
              child: OutlinedButton(
                onPressed: onReject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: NovaColors.error,
                  side: const BorderSide(color: NovaColors.error),
                  padding: EdgeInsets.zero,
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close_rounded, size: 14),
                    SizedBox(width: 2),
                    Text('No'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 72,
              height: 32,
              child: ElevatedButton(
                onPressed: onApprove,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NovaColors.greenDark,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_rounded, size: 14),
                    SizedBox(width: 2),
                    Text('Sí'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final String actionLabel;
  final VoidCallback onAction;
  final Color roleColor;
  final bool showScholarshipInfo;

  const _UserCard({
    required this.user,
    required this.actionLabel,
    required this.onAction,
    required this.roleColor,
    this.showScholarshipInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: NovaColors.greenLight,
          child: Text(
            user.profile.firstName[0],
            style: const TextStyle(color: NovaColors.greenDark),
          ),
        ),
        title: Row(
          children: [
            Text(
              user.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            if (showScholarshipInfo &&
                (user.scholarship.hasDesayuno || user.scholarship.hasComida))
              const Icon(Icons.star_rounded, size: 16, color: NovaColors.gold),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${user.email}\n${user.profile.area.toUpperCase()}'),
            if (showScholarshipInfo) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  user.role.toUpperCase(),
                  style: TextStyle(
                    color: roleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              if (user.scholarship.hasDesayuno || user.scholarship.hasComida)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 10,
                        color: NovaColors.gold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'BECADO: ${user.scholarship.hasDesayuno ? "DESAYUNO" : ""} ${user.scholarship.hasComida ? "COMIDA" : ""}',
                        style: const TextStyle(
                          color: NovaColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
        isThreeLine: true,
        trailing: SizedBox(
          width: 90,
          child: ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: NovaColors.greenDark,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Text(actionLabel),
          ),
        ),
      ),
    );
  }
}

class _ProductListTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductListTile({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: NovaColors.grayLight,
          ),
          child: product.photoUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    EnvConfig.getImageUrl(product.photoUrl!)!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.fastfood, color: NovaColors.greenDark),
                  ),
                )
              : const Icon(Icons.fastfood, color: NovaColors.greenDark),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${product.category.toUpperCase()} • \$${product.price.toStringAsFixed(2)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: NovaColors.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductFormDialog extends ConsumerStatefulWidget {
  final ProductModel? product;

  const _ProductFormDialog({this.product});

  @override
  ConsumerState<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late String _category;
  String? _photoUrl;
  File? _localImage;
  List<String> _selectedRestrictions = [];
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name);
    _descController = TextEditingController(text: widget.product?.description);
    _priceController = TextEditingController(
      text: widget.product?.price.toString(),
    );
    _category = widget.product?.category ?? 'antojitos';
    _photoUrl = widget.product?.photoUrl;
    _isVisible = widget.product?.isVisible ?? true;
    _selectedRestrictions =
        widget.product?.availableRestrictions.map((r) => r.id).toList() ?? [];
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _localImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final restrictions = ref.watch(adminProvider).restrictions;

    return AlertDialog(
      title: Text(
        widget.product == null ? 'Nuevo Producto' : 'Editar Producto',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: NovaColors.grayLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NovaColors.grayMedium),
                  ),
                  child: _localImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_localImage!, fit: BoxFit.cover),
                        )
                      : (_photoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  EnvConfig.getImageUrl(_photoUrl!)!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 40,
                                    color: NovaColors.grayMedium,
                                  ),
                                  Text(
                                    'Subir Foto',
                                    style: TextStyle(
                                      color: NovaColors.grayMedium,
                                    ),
                                  ),
                                ],
                              )),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v?.isEmpty == true ? 'Obligatorio' : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    double.tryParse(v ?? '') == null ? 'Precio inválido' : null,
              ),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: ['antojitos', 'desayuno', 'comida', 'especiales']
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              SwitchListTile(
                title: const Text('Visible en App'),
                value: _isVisible,
                onChanged: (v) => setState(() => _isVisible = v),
              ),
              const Divider(),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Restricciones Aplicables:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              if (restrictions.isEmpty)
                const Text(
                  'No hay restricciones configuradas',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                )
              else
                Wrap(
                  spacing: 8,
                  children: restrictions.map((r) {
                    final isSelected = _selectedRestrictions.contains(r.id);
                    return FilterChip(
                      label: Text(r.name, style: const TextStyle(fontSize: 10)),
                      selected: isSelected,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _selectedRestrictions.add(r.id);
                          } else {
                            _selectedRestrictions.remove(r.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: NovaColors.greenDark,
            foregroundColor: Colors.white,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    String? finalPhotoUrl = _photoUrl;

    // Subir imagen local si existe
    if (_localImage != null) {
      final uploadedUrl = await ref
          .read(adminProvider.notifier)
          .uploadImage(_localImage!.path);
      if (uploadedUrl != null) {
        finalPhotoUrl = uploadedUrl;
      } else {
        // Falló la subida de imagen
        if (mounted) {
          final errorMsg =
              ref.read(adminProvider).error ??
              'Error desconocido al subir imagen';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudo subir la imagen: $errorMsg'),
              backgroundColor: NovaColors.error,
            ),
          );
        }
        return; // Detener el guardado si la imagen falla
      }
    }

    final data = {
      'name': _nameController.text,
      'description': _descController.text,
      'price': double.parse(_priceController.text),
      'category': _category,
      'photoUrl': finalPhotoUrl,
      'availableRestrictions': _selectedRestrictions,
      'isVisible': _isVisible,
    };

    final bool isNewProduct = widget.product == null;
    bool shouldNotify = false;

    if (isNewProduct && mounted) {
      shouldNotify = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('¿Deseas promocionar este producto?'),
              content: const Text(
                'Se enviará una notificación push con la imagen y descripción '
                'de este producto a todos los clientes activos de la cafetería.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NovaColors.greenDark,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Promocionar'),
                ),
              ],
            ),
          ) ??
          false;
    }

    if (shouldNotify) {
      data['notifyCustomers'] = true;
    }

    if (widget.product == null) {
      await ref.read(adminProvider.notifier).createProduct(data);
    } else {
      await ref
          .read(adminProvider.notifier)
          .updateProduct(widget.product!.id, data);
    }

    if (mounted) Navigator.pop(context);
  }
}
