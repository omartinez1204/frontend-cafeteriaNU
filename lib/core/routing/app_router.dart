import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_screen.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/menu/presentation/screens/menu_screen.dart';
import '../../features/orders/presentation/screens/cart_screen.dart';
import '../../features/orders/presentation/screens/checkout_screen.dart';
import '../../features/orders/presentation/screens/order_success_screen.dart';
import '../../features/orders/presentation/screens/my_orders_screen.dart';
import '../../features/kitchen/presentation/screens/kitchen_screen.dart';
import '../../features/cashier/presentation/screens/cashier_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

/// Provider del router que escucha cambios en authState
final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Usar when para determinar el estado de autenticación
      return authState.when(
        initial: () => null, // Esperar a que termine la verificación
        loading: () => null,
        authenticated: (user) {
          // Si está autenticado y está en login/register, redirigir según rol
          if (isAuthRoute) {
            final role = user.role;
            if (role == 'admin') return '/admin';
            if (role == 'cocina') return '/kitchen';
            if (role == 'cajero') return '/cashier';
            return '/home';
          }
          return null;
        },
        unauthenticated: (_) {
          // Si NO está autenticado y NO está en login/register, ir a login
          if (!isAuthRoute) return '/login';
          return null;
        },
        error: (_) {
          if (!isAuthRoute) return '/login';
          return null;
        },
      );
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/menu',
        name: 'menu',
        builder: (context, state) => const MenuScreen(),
      ),
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order-success',
        name: 'order-success',
        builder: (context, state) => const OrderSuccessScreen(),
      ),
      GoRoute(
        path: '/my-orders',
        name: 'my-orders',
        builder: (context, state) => const MyOrdersScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: '/kitchen',
        name: 'kitchen',
        builder: (context, state) => const KitchenScreen(),
      ),
      GoRoute(
        path: '/cashier',
        name: 'cashier',
        builder: (context, state) => const CashierScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Ruta no encontrada: ${state.error}'),
      ),
    ),
  );
});
