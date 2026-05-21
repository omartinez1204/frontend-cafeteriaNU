import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@cafeterianova.com');
  final _passwordController = TextEditingController(text: '123456');
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await ref.read(authStateProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Escuchar errores
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      next.whenOrNull(
        error: (message) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
      );
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo institucional ──
                  _NovaLogo(),
                  const SizedBox(height: 24),

                  // ── Título ──
                  Text(
                    'CafeteriaNova',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: NovaColors.greenDark,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 8),
                  Text(
                    'Inicia sesión para continuar',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 400.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 48),

                  // ── Email ──
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu correo';
                      }
                      if (!value.contains('@')) {
                        return 'Correo inválido';
                      }
                      return null;
                    },
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 600.ms)
                      .slideX(begin: -0.1, end: 0),

                  const SizedBox(height: 16),

                  // ── Contraseña ──
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(
                              () => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu contraseña';
                      }
                      if (value.length < 6) {
                        return 'Mínimo 6 caracteres';
                      }
                      return null;
                    },
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 700.ms)
                      .slideX(begin: -0.1, end: 0),

                  const SizedBox(height: 32),

                  // ── Botón de login ──
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Iniciar sesión'),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 800.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 20),

                  // ── Link a registro ──
                  TextButton(
                    onPressed: () {
                      context.go('/register');
                    },
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: '¿No tienes cuenta? ',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const TextSpan(
                            text: 'Regístrate',
                            style: TextStyle(
                              color: NovaColors.greenMedium,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 900.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo institucional de CafeteriaNova con diseño NovaUniversitas
class _NovaLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                NovaColors.greenDark,
                NovaColors.greenMedium,
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: NovaColors.greenDark.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'CN',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: NovaColors.goldLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'NOVAUNIVERSITAS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: NovaColors.gold,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 800.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
  }
}
