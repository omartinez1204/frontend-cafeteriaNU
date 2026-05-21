import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/config/env_config.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../admin/presentation/providers/admin_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';

/// Provider para manejar el estado del perfil (carga, error, etc.)
final profileStateProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return ProfileNotifier(authRepository, ref);
});

class ProfileState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;

  const ProfileState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
  });

  ProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      successMessage: successMessage,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final AuthRepository _authRepository;
  final Ref _ref;

  ProfileNotifier(this._authRepository, this._ref) : super(const ProfileState());

  Future<UserModel?> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      final updatedUser = await _authRepository.updateProfile(data);
      // Actualizar el estado de autenticación con el usuario actualizado
      _ref.read(authStateProvider.notifier).updateUser(updatedUser);
      state = state.copyWith(isSaving: false, successMessage: 'Perfil actualizado exitosamente');
      return updatedUser;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Error al actualizar perfil: ${e.toString()}');
      return null;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      await _authRepository.changePassword(currentPassword, newPassword);
      state = state.copyWith(isSaving: false, successMessage: 'Contraseña cambiada exitosamente');
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Error al cambiar contraseña: ${e.toString()}');
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _nicknameController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  String _selectedArea = 'alumno';
  File? _localImage;
  bool _showPasswordForm = false;

  @override
  void initState() {
    super.initState();
    final user = _getCurrentUser();
    _firstNameController = TextEditingController(text: user?.profile.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.profile.lastName ?? '');
    _nicknameController = TextEditingController(text: user?.profile.nickname ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _selectedArea = user?.profile.area ?? 'alumno';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  UserModel? _getCurrentUser() {
    final authState = ref.read(authStateProvider);
    UserModel? user;
    authState.whenOrNull(authenticated: (u) => user = u);
    return user;
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

  Future<void> _saveProfile() async {
    final data = <String, dynamic>{
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'nickname': _nicknameController.text.trim(),
      'area': _selectedArea,
    };

    // Si hay imagen local, subirla primero
    if (_localImage != null) {
      // Usar el provider de admin para subir imagen (reutiliza el endpoint de uploads)
      final adminNotifier = ref.read(adminProvider.notifier);
      final uploadedUrl = await adminNotifier.uploadImage(_localImage!.path);
      if (uploadedUrl != null) {
        data['photoUrl'] = uploadedUrl;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo subir la imagen'),
              backgroundColor: NovaColors.error,
            ),
          );
        }
        return;
      }
    }

    final updatedUser = await ref.read(profileStateProvider.notifier).updateProfile(data);
    if (updatedUser != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: NovaColors.greenDark,
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos los campos son obligatorios'),
          backgroundColor: NovaColors.error,
        ),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La nueva contraseña debe tener al menos 6 caracteres'),
          backgroundColor: NovaColors.error,
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: NovaColors.error,
        ),
      );
      return;
    }

    final success = await ref.read(profileStateProvider.notifier).changePassword(currentPassword, newPassword);
    if (success && mounted) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() => _showPasswordForm = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña cambiada exitosamente'),
          backgroundColor: NovaColors.greenDark,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _getCurrentUser();
    final profileState = ref.watch(profileStateProvider);
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: const Center(child: Text('No se pudo cargar la información del usuario')),
      );
    }

    final initial = user.profile.firstName.isNotEmpty
        ? user.profile.firstName[0].toUpperCase()
        : 'U';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Foto de perfil ──
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: NovaColors.greenLight,
                    backgroundImage: _localImage != null
                        ? FileImage(_localImage!)
                        : (user.profile.photoUrl != null
                            ? NetworkImage(EnvConfig.getImageUrl(user.profile.photoUrl!)!)
                            : null),
                    child: (_localImage == null && user.profile.photoUrl == null)
                        ? Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: NovaColors.greenDark,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: NovaColors.greenDark,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca para cambiar foto',
              style: theme.textTheme.bodySmall?.copyWith(color: NovaColors.grayMedium),
            ),
            const SizedBox(height: 24),

            // ── Información del usuario ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Datos Personales',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre(s)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Apellidos',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: 'Apodo / Nickname (opcional)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedArea,
                      decoration: const InputDecoration(
                        labelText: 'Área',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'alumno', child: Text('Alumno')),
                        DropdownMenuItem(value: 'docente', child: Text('Docente')),
                        DropdownMenuItem(value: 'administrativo', child: Text('Administrativo')),
                        DropdownMenuItem(value: 'operativo', child: Text('Operativo')),
                        DropdownMenuItem(value: 'otro', child: Text('Otro')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedArea = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    // Email (solo lectura)
                    TextField(
                      controller: TextEditingController(text: user.email),
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        prefixIcon: Icon(Icons.email_rounded),
                      ),
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: profileState.isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NovaColors.greenDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: profileState.isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Guardar Cambios', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Cambiar contraseña ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _showPasswordForm = !_showPasswordForm),
                      child: Row(
                        children: [
                          Icon(Icons.lock_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Cambiar Contraseña',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Icon(
                            _showPasswordForm ? Icons.expand_less : Icons.expand_more,
                            color: NovaColors.grayMedium,
                          ),
                        ],
                      ),
                    ),
                    if (_showPasswordForm) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _currentPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña actual',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _newPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Nueva contraseña',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar nueva contraseña',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: profileState.isSaving ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: NovaColors.gold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: profileState.isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Cambiar Contraseña', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Selector de Tema ──
            _buildThemeSelector(theme),
            const SizedBox(height: 16),

            // ── Información de la cuenta ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_rounded, color: NovaColors.grayMedium),
                        const SizedBox(width: 8),
                        Text('Información de la Cuenta',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    _infoRow('Rol', user.role.toUpperCase()),
                    _infoRow('Estado', user.isActive ? 'Activo' : 'Inactivo'),
                    if (user.createdAt != null)
                      _infoRow('Miembro desde', _formatDate(user.createdAt!)),
                    if (user.scholarship.hasDesayuno || user.scholarship.hasComida)
                      _infoRow(
                        'Becas',
                        '${user.scholarship.hasDesayuno ? "Desayuno " : ""}${user.scholarship.hasComida ? "Comida" : ""}',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(ThemeData theme) {
    final activeTheme = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Personalizar Tema',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _themeOption(
                  style: AppThemeStyle.light,
                  label: 'Claro',
                  primaryColor: const Color(0xFF1A4731),
                  activeTheme: activeTheme,
                  onTap: () => themeNotifier.setTheme(AppThemeStyle.light),
                ),
                _themeOption(
                  style: AppThemeStyle.dark,
                  label: 'Oscuro',
                  primaryColor: const Color(0xFF2E7D52),
                  activeTheme: activeTheme,
                  onTap: () => themeNotifier.setTheme(AppThemeStyle.dark),
                ),
                _themeOption(
                  style: AppThemeStyle.pink,
                  label: 'Rosa',
                  primaryColor: const Color(0xFFD81B60),
                  activeTheme: activeTheme,
                  onTap: () => themeNotifier.setTheme(AppThemeStyle.pink),
                ),
                _themeOption(
                  style: AppThemeStyle.purple,
                  label: 'Púrpura',
                  primaryColor: const Color(0xFFAB47BC),
                  activeTheme: activeTheme,
                  onTap: () => themeNotifier.setTheme(AppThemeStyle.purple),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeOption({
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: NovaColors.grayMedium)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
