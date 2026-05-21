import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);

    // Extraer usuario del estado autenticado
    String? displayName;
    String? photoUrl;
    authState.whenOrNull(
      authenticated: (user) {
        // Mostrar nickname si existe, sino el firstName
        displayName = user.profile.nickname ?? user.profile.firstName;
        photoUrl = user.profile.photoUrl;
      },
    );

    // Inicial del usuario para el avatar
    final nameForInitial = displayName;
    final initial = (nameForInitial != null && nameForInitial.isNotEmpty)
        ? nameForInitial[0].toUpperCase()
        : 'U';






    // Construir URL completa de la imagen
    final imageUrl = EnvConfig.getImageUrl(photoUrl);



    return Scaffold(
      appBar: AppBar(
        title: const Text('CafeteriaNova'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Perfil del usuario ──
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: NovaColors.greenDark,
                  backgroundImage: imageUrl != null
                      ? NetworkImage(imageUrl)
                      : null,
                  child: imageUrl == null
                      ? Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),



                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Hola, ${displayName ?? 'Usuario'}!',

                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: NovaColors.greenDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '¿Qué se te antoja hoy?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .slideX(begin: -0.1, end: 0),

            const SizedBox(height: 32),

            // ── Cards de acceso rápido ──
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.9,
                children: [
                  _QuickAccessCard(
                    icon: Icons.menu_book_rounded,
                    title: 'Menú',
                    subtitle: 'Ver productos disponibles',
                    color: NovaColors.greenDark,
                    delay: 200,
                    onTap: () => context.push('/menu'),
                  ),
                  _QuickAccessCard(
                    icon: Icons.shopping_bag_rounded,
                    title: 'Mi pedido',
                    subtitle: 'Ver pedidos en curso',
                    color: NovaColors.gold,
                    delay: 300,
                    onTap: () => context.push('/my-orders'),
                  ),
                  _QuickAccessCard(
                    icon: Icons.receipt_long_rounded,
                    title: 'Historial',
                    subtitle: 'Tus pedidos completados',
                    color: NovaColors.greenMedium,
                    delay: 400,
                    onTap: () => context.push('/my-orders'),
                  ),
                  _QuickAccessCard(
                    icon: Icons.person_rounded,
                    title: 'Perfil',
                    subtitle: 'Tus datos y preferencias',
                    color: NovaColors.gold,
                    delay: 500,
                    onTap: () => context.push('/profile'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final int delay;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Icono con fondo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const Spacer(),
              // Título
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: NovaColors.greenDark,
                ),
              ),
              const SizedBox(height: 4),
              // Subtítulo
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: delay.ms)
        .slideY(begin: 0.2, end: 0)
        .scaleXY(begin: 0.95, end: 1.0);
  }
}
