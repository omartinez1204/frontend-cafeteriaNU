import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/user_model.dart';
import '../providers/cart_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/student_search_provider.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import 'package:go_router/go_router.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _notasController = TextEditingController();
  final _searchController = TextEditingController();
  String _paymentMethod = 'efectivo';
  bool _isSubmitting = false;
  bool _isCashierMode = false;
  UserModel? _selectedStudent;

  @override
  void initState() {
    super.initState();
    // Auto-seleccionar beca si el usuario tiene beca y todos los items están cubiertos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectScholarshipIfApplicable();
    });
  }

  void _autoSelectScholarshipIfApplicable() {
    final authState = ref.read(authStateProvider);
    final cartState = ref.read(cartProvider);
    authState.maybeWhen(
      authenticated: (user) {
        // Si es cajero/admin, no auto-seleccionar beca (ellos deciden manualmente)
        if (user.role == 'cajero' || user.role == 'admin') {
          return;
        }
        final scholarship = user.scholarship;
        if (!scholarship.hasDesayuno && !scholarship.hasComida) return;

        final allCovered =
            _allItemsCoveredByScholarship(cartState, scholarship);
        if (allCovered) {
          setState(() => _paymentMethod = 'beca');
        }
      },
      orElse: () {},
    );
  }

  /// Calcula cuánto cubre la beca del total del carrito.
  /// Retorna el monto cubierto por la beca.
  double _calculateScholarshipCoverage(
      CartState cartState, UserScholarship scholarship) {
    double covered = 0;
    for (final item in cartState.items) {
      final category = item.product.category;
      if (category == 'desayuno' && scholarship.hasDesayuno) {
        covered += item.subtotal;
      } else if (category == 'comida' && scholarship.hasComida) {
        covered += item.subtotal;
      }
    }
    return covered;
  }

  /// Calcula el monto que el usuario debe pagar (no cubierto por beca).
  double _calculateAmountDue(CartState cartState, UserScholarship? scholarship) {
    if (_paymentMethod != 'beca' || scholarship == null) {
      return cartState.total;
    }
    final covered = _calculateScholarshipCoverage(cartState, scholarship);
    return (cartState.total - covered).clamp(0, double.infinity);
  }

  /// Verifica si todos los items del carrito están cubiertos por beca.
  bool _allItemsCoveredByScholarship(
      CartState cartState, UserScholarship scholarship) {
    for (final item in cartState.items) {
      final category = item.product.category;
      final isCovered = (category == 'desayuno' && scholarship.hasDesayuno) ||
          (category == 'comida' && scholarship.hasComida);
      if (!isCovered) return false;
    }
    return true;
  }

  /// Retorna la descripción de la beca para mostrar al usuario.
  String _getScholarshipDescription(UserScholarship scholarship) {
    if (scholarship.hasDesayuno && scholarship.hasComida) {
      return 'Beca de Desayuno y Comida';
    } else if (scholarship.hasDesayuno) {
      return 'Beca de Desayuno';
    } else if (scholarship.hasComida) {
      return 'Beca de Comida';
    }
    return '';
  }

  @override
  void dispose() {
    _notasController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);

    // Obtener datos de beca del usuario
    UserScholarship? scholarship;
    bool hasScholarship = false;
    bool isCashier = false;

    authState.maybeWhen(
      authenticated: (user) {
        scholarship = user.scholarship;
        hasScholarship =
            user.scholarship.hasDesayuno || user.scholarship.hasComida;
        isCashier = user.role == 'cajero' || user.role == 'admin';
      },
      orElse: () {},
    );

    // Si es cajero, inicializar el modo beca si está activado
    if (isCashier && _isCashierMode && _paymentMethod != 'beca') {
      // No cambiar aquí, se maneja en el toggle
    }

    final amountDue = _paymentMethod == 'beca' && isCashier
        ? 0.0
        : _calculateAmountDue(cartState, scholarship);
    final scholarshipCovers = _paymentMethod == 'beca' && scholarship != null
        ? _calculateScholarshipCoverage(cartState, scholarship!)
        : 0.0;
    final allCovered = hasScholarship &&
        _paymentMethod == 'beca' &&
        _allItemsCoveredByScholarship(cartState, scholarship!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Pedido'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner de beca (si aplica y está seleccionada) ──
            if (_paymentMethod == 'beca' && hasScholarship) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      NovaColors.greenDark.withValues(alpha: 0.1),
                      NovaColors.gold.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: NovaColors.gold.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.school_rounded,
                        color: NovaColors.gold, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getScholarshipDescription(scholarship!),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: NovaColors.greenDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            allCovered
                                ? '¡Tu pedido está cubierto por tu beca! Solo espera tu orden en la cafetería.'
                                : 'Tu beca cubre \$${scholarshipCovers.toStringAsFixed(2)} de tu pedido.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Resumen del pedido ──
            Text('Resumen del pedido',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...cartState.items.map((item) {
              // Determinar si este item está cubierto por beca
              final isCoveredByScholarship = _paymentMethod == 'beca' &&
                  scholarship != null &&
                  ((item.product.category == 'desayuno' &&
                          scholarship!.hasDesayuno) ||
                      (item.product.category == 'comida' &&
                          scholarship!.hasComida));

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCoveredByScholarship
                          ? NovaColors.gold.withValues(alpha: 0.2)
                          : NovaColors.greenLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: isCoveredByScholarship
                          ? const Icon(Icons.school_rounded,
                              color: NovaColors.gold, size: 20)
                          : Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: NovaColors.greenDark,
                              ),
                            ),
                    ),
                  ),
                  title: Text(item.product.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.restrictions.isNotEmpty)
                        Text(
                          item.restrictions.join(', '),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: NovaColors.greenDark),
                        ),
                      if (isCoveredByScholarship)
                        Text(
                          'Cubierto por beca',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: NovaColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  trailing: isCoveredByScholarship
                      ? Text(
                          '\$0.00',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: NovaColors.gold,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: NovaColors.grayMedium,
                          ),
                        )
                      : Text(
                          '\$${item.subtotal.toStringAsFixed(2)}',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              );
            }),

            const Divider(height: 32),

            // ── Total ──
            if (_paymentMethod == 'beca' && scholarshipCovers > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal',
                      style: theme.textTheme.bodyLarge),
                  Text(
                    '\$${cartState.total.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.school_rounded,
                          color: NovaColors.gold, size: 18),
                      const SizedBox(width: 6),
                      Text('Descuento por beca',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: NovaColors.gold,
                          )),
                    ],
                  ),
                  Text(
                    '-\$${scholarshipCovers.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: NovaColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total a pagar',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  '\$${amountDue.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: allCovered ? NovaColors.greenDark : NovaColors.gold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Método de pago ──
            Text('Método de pago',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // ── Para cajeros: toggle de pedido para becado ──
            if (isCashier) ...[
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: _isCashierMode
                    ? RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: NovaColors.gold, width: 2),
                      )
                    : null,
                child: SwitchListTile(
                  title: Row(
                    children: [
                      const Icon(Icons.school_rounded,
                          color: NovaColors.gold, size: 22),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Pedido para alumno becado',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    _isCashierMode
                        ? 'El pedido NO se cobrará (cubierto por beca)'
                        : 'Activar si el alumno cuenta con beca',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: _isCashierMode,
                  activeTrackColor: NovaColors.gold.withValues(alpha: 0.5),
                  activeThumbColor: NovaColors.gold,
                  onChanged: (value) {
                    setState(() {
                      _isCashierMode = value;
                      _paymentMethod = value ? 'beca' : 'efectivo';
                    });
                  },
                ),
              ),
              if (_isCashierMode) ...[
                // ── Buscador de alumno becado ──
                Text('Buscar alumno becado',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Nombre, apellido o email del alumno...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(studentSearchProvider.notifier).clear();
                              setState(() => _selectedStudent = null);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _selectedStudent = null);
                    ref.read(studentSearchProvider.notifier).search(value);
                  },
                ),
                const SizedBox(height: 8),

                // ── Resultados de búsqueda ──
                Consumer(
                  builder: (context, ref, _) {
                    final searchState = ref.watch(studentSearchProvider);
                    if (searchState.isLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    if (searchState.error != null) {
                      return Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          searchState.error!,
                          style: TextStyle(color: NovaColors.error),
                        ),
                      );
                    }
                    if (searchState.students.isEmpty &&
                        searchState.query.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'No se encontraron alumnos con "$searchState.query"',
                          style: TextStyle(color: NovaColors.grayMedium),
                        ),
                      );
                    }
                    if (searchState.students.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: searchState.students.map((student) {
                        final isSelected = _selectedStudent?.id == student.id;
                        final scholarshipDesc = student.scholarship.hasDesayuno && student.scholarship.hasComida
                            ? 'Desayuno y Comida'
                            : student.scholarship.hasDesayuno
                                ? 'Solo Desayuno'
                                : student.scholarship.hasComida
                                    ? 'Solo Comida'
                                    : 'Sin beca asignada';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 4),
                          shape: isSelected
                              ? RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                      color: NovaColors.gold, width: 2),
                                )
                              : null,
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor: isSelected
                                  ? NovaColors.gold
                                  : NovaColors.greenLight,
                              child: Icon(
                                Icons.person_rounded,
                                color: isSelected
                                    ? Colors.white
                                    : NovaColors.greenDark,
                              ),
                            ),
                            title: Text(student.fullName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(student.email),
                                Text(
                                  'Beca: $scholarshipDesc',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: student.scholarship.hasDesayuno ||
                                            student.scholarship.hasComida
                                        ? NovaColors.gold
                                        : NovaColors.grayMedium,
                                  ),
                                ),
                              ],
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle_rounded,
                                    color: NovaColors.greenDark)
                                : null,
                            onTap: () {
                              setState(() => _selectedStudent = student);
                              _searchController.text = student.fullName;
                              ref
                                  .read(studentSearchProvider.notifier)
                                  .clear();
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                // ── Alumno seleccionado ──
                if (_selectedStudent != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          NovaColors.greenDark.withValues(alpha: 0.1),
                          NovaColors.gold.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: NovaColors.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: NovaColors.greenDark, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pedido sin costo para ${_selectedStudent!.fullName}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: NovaColors.greenDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Este pedido se registrará como cubierto por beca. Total: \$0.00',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ],

            // Opción de beca (primero si el usuario tiene beca y todos los items cubiertos)
            if (!isCashier && hasScholarship &&
                _allItemsCoveredByScholarship(cartState, scholarship!))
              _PaymentMethodOption(
                value: 'beca',
                label: 'Beca de Alimentos (${_getScholarshipDescription(scholarship!)})',
                icon: Icons.school_rounded,
                selected: _paymentMethod == 'beca',
                onSelected: (v) => setState(() => _paymentMethod = v),
                highlight: true,
              ),

            // Solo mostrar otros métodos de pago si no todos los items están cubiertos
            // Para clientes normales
            if (!isCashier && !allCovered) ...[
              _PaymentMethodOption(
                value: 'efectivo',
                label: 'Efectivo',
                icon: Icons.money_rounded,
                selected: _paymentMethod == 'efectivo',
                onSelected: (v) => setState(() => _paymentMethod = v),
              ),
            ],

            const SizedBox(height: 24),

            // ── Notas ──
            Text('Notas (opcional)',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _notasController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ej: Sin cebolla, extra salsa...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) {
                ref.read(cartProvider.notifier).setNotes(v);
              },
            ),

            const SizedBox(height: 32),

            // ── Botón de confirmar ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NovaColors.greenDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        allCovered
                            ? 'Confirmar Pedido con Beca'
                            : 'Confirmar Pedido',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitOrder() async {
    setState(() => _isSubmitting = true);

    try {
      final cartState = ref.read(cartProvider);
      final ordersNotifier = ref.read(ordersProvider.notifier);

      // Determinar si la beca cubre todo
      final authState = ref.read(authStateProvider);
      bool isFullScholarship = false;
      authState.maybeWhen(
        authenticated: (user) {
          if (_paymentMethod == 'beca') {
            isFullScholarship =
                _allItemsCoveredByScholarship(cartState, user.scholarship);
          }
        },
        orElse: () {},
      );

      // Formatear items para la API
      final items = cartState.items
          .map((item) => {
                'productId': item.product.id,
                'quantity': item.quantity,
                'restrictions': item.restrictions,
              })
          .toList();

      await ordersNotifier.create(
        items: items,
        paymentMethod: _paymentMethod,
        customerNote: _notasController.text.isNotEmpty
            ? _notasController.text
            : null,
        scholarshipUserId: _selectedStudent?.id,
      );

      // Limpiar carrito
      ref.read(cartProvider.notifier).clear();

      if (mounted) {
        // Navegar a la pantalla de éxito con indicador de beca
        context.pushReplacement('/order-success', extra: {
          'isScholarship': _paymentMethod == 'beca',
          'isFullScholarship': isFullScholarship,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear pedido: $e'),
            backgroundColor: NovaColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _PaymentMethodOption extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool selected;
  final ValueChanged<String> onSelected;
  final bool highlight;

  const _PaymentMethodOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: highlight && selected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: NovaColors.gold, width: 2),
            )
          : null,
      child: InkWell(
        onTap: () => onSelected(value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon,
                  color: highlight ? NovaColors.gold : NovaColors.greenDark),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: highlight && selected ? NovaColors.gold : null,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected
                    ? (highlight ? NovaColors.gold : NovaColors.greenDark)
                    : NovaColors.grayMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
