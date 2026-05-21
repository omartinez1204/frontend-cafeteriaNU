import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/auth_models.dart';
import '../../data/auth_repository.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedArea = 'alumno';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = RegisterRequest(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: 'cliente',
      profile: RegisterProfile(
        firstName: _nombreController.text.trim(),
        lastName: _apellidoController.text.trim().isEmpty
            ? _nombreController.text.trim()
            : _apellidoController.text.trim(),
        nickname: _nombreController.text.trim().split(' ').first,
        area: _selectedArea,
      ),
    );

    try {
      // Llamar al repositorio directamente para tener control total del flujo
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.register(request);

      // El registro fue exitoso, limpiar tokens (cliente requiere activación)
      await authRepository.logout();

      if (mounted) {
        setState(() => _isLoading = false);

        // Mostrar diálogo de activación presencial
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Registro Exitoso', style: TextStyle(color: NovaColors.greenDark)),
            content: const Text('Tu cuenta ha sido creada exitosamente. Por favor acude físicamente a la cafetería de NovaUniversitas para que un administrador active tu cuenta.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.go('/login');
                },
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        String errorMsg;
        final errorStr = e.toString();
        if (errorStr.contains('409')) {
          errorMsg = 'El email ya está registrado';
        } else if (errorStr.contains('SocketException') ||
            errorStr.contains('Connection refused')) {
          errorMsg = 'Error de conexión con el servidor';
        } else {
          errorMsg = 'Error inesperado. Intenta de nuevo.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Encabezado ──
                Text(
                  'Regístrate en CafeteriaNova',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: NovaColors.greenDark,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideX(begin: -0.1, end: 0),

                const SizedBox(height: 8),
                Text(
                  'Completa tus datos para crear tu cuenta',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 100.ms)
                    .slideX(begin: -0.1, end: 0),

                const SizedBox(height: 32),

                // ── Sección: Información personal ──
                _SectionHeader(title: 'Información personal')
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 200.ms),

                const SizedBox(height: 16),

                // Nombre
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre(s)',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu nombre';
                    }
                    return null;
                  },
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 300.ms)
                    .slideX(begin: -0.05, end: 0),

                const SizedBox(height: 16),

                // Apellido
                TextFormField(
                  controller: _apellidoController,
                  decoration: const InputDecoration(
                    labelText: 'Apellido (opcional)',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 350.ms)
                    .slideX(begin: -0.05, end: 0),

                const SizedBox(height: 16),

                // Área / Tipo de usuario
                DropdownButtonFormField<String>(
                  value: _selectedArea,
                  decoration: const InputDecoration(
                    labelText: 'Área',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'alumno', child: Text('Alumno/a')),
                    DropdownMenuItem(value: 'docente', child: Text('Docente')),
                    DropdownMenuItem(value: 'operativo', child: Text('Operativo')),
                    DropdownMenuItem(value: 'administrativo', child: Text('Administrativo')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedArea = v);
                  },
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 400.ms)
                    .slideX(begin: -0.05, end: 0),

                const SizedBox(height: 32),

                // ── Sección: Acceso ──
                _SectionHeader(title: 'Datos de acceso')
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 450.ms),

                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  textInputAction: TextInputAction.next,
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
                    .fadeIn(duration: 400.ms, delay: 500.ms)
                    .slideX(begin: -0.05, end: 0),

                const SizedBox(height: 16),

                // Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
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
                      return 'Ingresa una contraseña';
                    }
                    if (value.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }
                    return null;
                  },
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 550.ms)
                    .slideX(begin: -0.05, end: 0),

                const SizedBox(height: 16),

                // Confirmar contraseña
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegister(),
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(
                            () => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 600.ms)
                    .slideX(begin: -0.05, end: 0),

                const SizedBox(height: 32),

                // ── Botón de registro ──
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Crear cuenta'),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 700.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 16),

                // ── Link a login ──
                TextButton(
                  onPressed: () {
                    context.go('/login');
                  },
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: '¿Ya tienes cuenta? ',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const TextSpan(
                          text: 'Inicia sesión',
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
                    .fadeIn(duration: 500.ms, delay: 800.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Encabezado de sección para agrupar campos del formulario
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: NovaColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: NovaColors.greenDark,
                letterSpacing: 0.5,
              ),
        ),
      ],
    );
  }
}
