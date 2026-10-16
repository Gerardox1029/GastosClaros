import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastos_claros/core/theme.dart';
import 'package:gastos_claros/shared/providers/app_providers.dart';
import 'package:gastos_claros/shared/widgets/add_entry_modal.dart';
import 'package:gastos_claros/features/saldo/saldo_screen.dart';
import 'package:gastos_claros/features/gastos/gastos_screen.dart';

/// Dashboard principal con Bottom Navigation Bar de 3 tabs
/// y botón "+" elevado central con opciones Gasto/Saldo.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabCtrl;
  late Animation<double> _fabScale;

  final List<Widget> _screens = const [
    SaldoScreen(),
    GastosScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.9,
      upperBound: 1.0,
    )..value = 1.0;

    _fabScale = _fabCtrl;
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
  }

  void _onFabTap() {
    HapticFeedback.mediumImpact();
    _showAddOptions();
  }

  void _onFabTapDown(TapDownDetails _) {
    _fabCtrl.animateTo(0.9);
  }

  void _onFabTapUp(TapUpDetails _) {
    _fabCtrl.animateTo(1.0);
  }

  void _onFabTapCancel() {
    _fabCtrl.animateTo(1.0);
  }

  /// Muestra bottom sheet con opciones: Gasto o Saldo.
  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => _AddOptionsSheet(
        onSelectType: (type) {
          Navigator.of(context).pop();
          // Navegar al tab correcto
          final tabIndex = type == 'ingreso' ? 0 : 1;
          ref.read(selectedTabProvider.notifier).state = tabIndex;
          // Abrir modal
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) showAddEntryModal(context, type: type);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(selectedTabProvider);

    return Scaffold(
      backgroundColor: AppColors.deepPurpleBg,
      body: IndexedStack(
        index: selectedTab,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(selectedTab),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNav(int selectedTab) {
    return BottomAppBar(
      color: AppColors.surfacePurple,
      elevation: 0,
      notchMargin: 10,
      shape: const CircularNotchedRectangle(),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.mutedPurple.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Tab Saldo
            _buildNavItem(
              index: 0,
              selectedIndex: selectedTab,
              icon: Icons.account_balance_wallet_rounded,
              label: 'Saldo',
            ),
            // Espacio para el FAB
            const SizedBox(width: 72),
            // Tab Gastos
            _buildNavItem(
              index: 1,
              selectedIndex: selectedTab,
              icon: Icons.receipt_long_rounded,
              label: 'Gastos',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required int selectedIndex,
    required IconData icon,
    required String label,
  }) {
    final isSelected = index == selectedIndex;
    return GestureDetector(
      onTap: () => ref.read(selectedTabProvider.notifier).state = index,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                key: ValueKey(isSelected),
                color: isSelected ? AppColors.accentPurple : AppColors.mutedPurple,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.accentPurple : AppColors.mutedPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: _onFabTap,
      onTapDown: _onFabTapDown,
      onTapUp: _onFabTapUp,
      onTapCancel: _onFabTapCancel,
      child: ScaleTransition(
        scale: _fabScale,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPurple.withOpacity(0.45),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: AppColors.whiteText,
            size: 32,
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet que muestra las opciones: Gasto o Saldo.
class _AddOptionsSheet extends StatelessWidget {
  final void Function(String type) onSelectType;

  const _AddOptionsSheet({required this.onSelectType});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfacePurple,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.modal),
        ),
        border: Border.all(
          color: AppColors.accentPurple.withOpacity(0.15),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.mutedPurple.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(
              '¿Qué deseas agregar?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Opción Saldo
            _buildOption(
              context,
              icon: Icons.account_balance_wallet_rounded,
              label: 'Saldo',
              subtitle: 'Registrar un ingreso o pago recibido',
              color: AppColors.successGreen,
              onTap: () => onSelectType('ingreso'),
            ),
            const SizedBox(height: AppSpacing.md),

            // Opción Gasto
            _buildOption(
              context,
              icon: Icons.receipt_long_rounded,
              label: 'Gasto',
              subtitle: 'Registrar comida, gasolina u otro gasto',
              color: AppColors.dangerRed,
              onTap: () => onSelectType('gasto'),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedText,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
