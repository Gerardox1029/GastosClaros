import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastos_claros/core/theme.dart';
import 'package:gastos_claros/shared/providers/app_providers.dart';
import 'package:gastos_claros/shared/widgets/add_entry_modal.dart';
import 'package:gastos_claros/shared/widgets/currency_widgets.dart';
import 'package:gastos_claros/shared/widgets/loading_spinner.dart';
import 'package:gastos_claros/shared/models/registro.dart';

/// Sección Saldo — muestra saldo actual, filtro de tiempo,
/// historial de ingresos y botón para agregar.
class SaldoScreen extends ConsumerStatefulWidget {
  const SaldoScreen({super.key});

  @override
  ConsumerState<SaldoScreen> createState() => _SaldoScreenState();
}

class _SaldoScreenState extends ConsumerState<SaldoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _listCtrl;

  @override
  void initState() {
    super.initState();
    _listCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _listCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(balanceProvider);
    final historyAsync = ref.watch(ingresosHistoryProvider);
    final filter = ref.watch(balanceFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.deepPurpleBg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mi Saldo',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded,
                          color: AppColors.mutedText),
                      onPressed: () {
                        ref.invalidate(balanceProvider);
                        ref.invalidate(ingresosHistoryProvider);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Panel Saldo Principal
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _buildBalancePanel(context, balanceAsync, filter, ref),
              ),
            ),

            // Historial de ingresos
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: Text(
                  'Últimos ingresos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.mutedText,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

            // Lista de ingresos
            historyAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: LoadingSpinner(),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: _buildError(context, e.toString(), () {
                  ref.invalidate(ingresosHistoryProvider);
                }),
              ),
              data: (registros) => registros.isEmpty
                  ? SliverToBoxAdapter(
                      child: _buildEmptyState(context, 'Sin ingresos aún'),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _buildRegistroItem(
                          context,
                          registros[i],
                          i,
                          isIngreso: true,
                        ),
                        childCount: registros.length,
                      ),
                    ),
            ),

            // Botón Agregar Saldo (dashed)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: _buildAddButton(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalancePanel(
    BuildContext context,
    AsyncValue balanceAsync,
    String filter,
    WidgetRef ref,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D2845), Color(0xFF3D3560)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card + 4),
        border: Border.all(
          color: AppColors.accentPurple.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPurple.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          const Text(
            'SALDO ACTUAL',
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Monto grande
          balanceAsync.when(
            loading: () => const LoadingSpinner(size: 28, strokeWidth: 2.5),
            error: (e, _) => const Text(
              'S/. —',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: AppColors.mutedText,
              ),
            ),
            data: (balance) => SaldoDisplay(saldo: balance.saldo),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Sub-totales
          balanceAsync.maybeWhen(
            data: (balance) => Row(
              children: [
                _buildSubTotal(
                  'Ingresos',
                  balance.totalIngresos,
                  AppColors.successGreen,
                  Icons.arrow_upward_rounded,
                ),
                const SizedBox(width: AppSpacing.lg),
                _buildSubTotal(
                  'Gastos',
                  balance.totalGastos,
                  AppColors.dangerRed,
                  Icons.arrow_downward_rounded,
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Filtro de tiempo
          _buildTimeFilter(filter, ref),
        ],
      ),
    );
  }

  Widget _buildSubTotal(
      String label, double amount, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              formatMonto(amount),
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeFilter(String currentFilter, WidgetRef ref) {
    const filters = ['1D', '7D', '14D', '1M'];
    return Row(
      children: filters
          .map(
            (f) => GestureDetector(
              onTap: () {
                ref.read(balanceFilterProvider.notifier).state = f;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: currentFilter == f
                      ? AppColors.accentPurple
                      : AppColors.deepPurpleBg.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: currentFilter == f
                        ? AppColors.accentPurple
                        : AppColors.mutedPurple.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: currentFilter == f
                        ? AppColors.whiteText
                        : AppColors.mutedText,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildRegistroItem(
    BuildContext context,
    Registro registro,
    int index, {
    required bool isIngreso,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index * 80)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 4,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfacePurple,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: AppColors.mutedPurple.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            // Ícono
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isIngreso ? AppColors.successGreen : AppColors.dangerRed)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isIngreso
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: isIngreso ? AppColors.successGreen : AppColors.dangerRed,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    registro.nombre.isNotEmpty
                        ? registro.nombreTruncado
                        : registro.descripcionTruncada,
                    style: const TextStyle(
                      color: AppColors.whiteText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    formatFecha(registro.fecha),
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Monto
            MontoText(
              monto: registro.monto,
              isIngreso: isIngreso,
              showSign: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => showAddEntryModal(context, type: 'ingreso'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: AppColors.accentPurple.withOpacity(0.5),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: AppColors.accentPurple,
              size: 20,
            ),
            SizedBox(width: AppSpacing.sm),
            Text(
              'Agregar Saldo',
              style: TextStyle(
                color: AppColors.accentPurple,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(
      BuildContext context, String message, VoidCallback onRetry) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.dangerRed, size: 36),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Error al cargar datos',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar',
                style: TextStyle(color: AppColors.accentPurple)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String msg) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded,
              color: AppColors.mutedPurple.withOpacity(0.4), size: 48),
          const SizedBox(height: AppSpacing.sm),
          Text(
            msg,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}
