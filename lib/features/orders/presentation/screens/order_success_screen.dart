import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class OrderSuccessScreen extends ConsumerWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Leer datos extra de la navegación (beca info)
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final isScholarship = extra?['isScholarship'] == true;
    final isFullScholarship = extra?['isFullScholarship'] == true;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isScholarship
                    ? Icons.school_rounded
                    : Icons.check_circle_rounded,
                size: 100,
                color: isScholarship ? NovaColors.gold : NovaColors.greenDark,
              ),
              const SizedBox(height: 24),
              Text(
                '¡Pedido Exitoso!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: NovaColors.greenDark,
                ),
              ),
              const SizedBox(height: 12),

              // Mensaje específico según tipo de pago
              if (isScholarship && isFullScholarship) ...[
                // Beca cubre todo el pedido
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        NovaColors.greenDark.withValues(alpha: 0.08),
                        NovaColors.gold.withValues(alpha: 0.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: NovaColors.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.card_membership_rounded,
                          color: NovaColors.gold, size: 36),
                      const SizedBox(height: 12),
                      Text(
                        '¡Tu beca cubre este pedido!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: NovaColors.gold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No necesitas realizar ningún pago. Puedes esperar tu orden directamente en la cafetería.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (isScholarship && !isFullScholarship) ...[
                // Beca cubre parcialmente
                Text(
                  'Tu beca cubre parte del pedido. Pasa a la cafetería para completar el pago del resto.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else ...[
                // Pago normal
                Text(
                  'Tu pedido ha sido registrado y está siendo procesado.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              const SizedBox(height: 8),
              Text(
                'Recibirás notificaciones cuando tu pedido esté listo.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NovaColors.greenDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Ir al Inicio',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  context.pushReplacement('/my-orders');
                },
                child: const Text('Ver mis pedidos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
