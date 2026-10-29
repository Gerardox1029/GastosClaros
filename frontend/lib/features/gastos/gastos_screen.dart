import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastos_claros/core/theme.dart';
import 'package:gastos_claros/shared/providers/app_providers.dart';
import 'package:gastos_claros/shared/widgets/add_entry_modal.dart';
import 'package:gastos_claros/shared/widgets/currency_widgets.dart';
import 'package:gastos_claros/shared/widgets/loading_spinner.dart';
import 'package:gastos_claros/shared/models/registro.dart';
import 'package:gastos_claros/shared/models/balance_response.dart';

/// Sección Gastos — muestra resumen de gastos y historial reciente.
class GastosScreen extends ConsumerWidget {
  const GastosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(balanceProvider);
    final historyAsync = ref.watch(gastosHistoryProvider);
    final filter = ref.watch(balanceFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.deepPurpleBg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
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
                      'Mis Gastos',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded,
                          color: AppColors.mutedText),
                      onPressed: () {
                        ref.invalidate(balanceProvider);
                        ref.invalidate(gastosHistoryProvider);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Panel de gastos
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _buildGastosPanel(context, balanceAsync, filter, ref),
              ),
            ),

            // Historial
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: Text(
                  'Historial de gastos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.mutedText,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

            historyAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: LoadingSpinner(),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: _buildError(context, () {
                  ref.invalidate(gastosHistoryProvider);
                }),
              ),
              data: (registros) => registros.isEmpty
                  ? SliverToBoxAdapter(
                      child: _buildEmptyState(context),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) =>
                            _buildGastoItem(context, registros[i], i),
                        childCount: registros.length,
                      ),
                    ),
            ),

            historyAsync.maybeWhen(
              data: (registros) =>
                  registros.length >= ref.watch(gastosHistoryLimitProvider)
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: TextButton(
                              onPressed: () => ref
                                  .read(gastosHistoryLimitProvider.notifier)
                                  .state += 5,
                              child: const Text('Ver más gastos'),
                            ),
                          ),
                        )
                      : const SliverToBoxAdapter(child: SizedBox.shrink()),
              orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // Botón agregar gasto
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: GestureDetector(
                  onTap: () => showAddEntryModal(context, type: 'gasto'),
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      border: Border.all(
                        color: AppColors.dangerRed.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          color: AppColors.dangerRed,
                          size: 20,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Agregar Gasto',
                          style: TextStyle(
                            color: AppColors.dangerRed,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGastosPanel(
    BuildContext context,
    AsyncValue<BalanceResponse> balanceAsync,
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
          colors: [Color(0xFF2D1F1F), Color(0xFF3D2828)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card + 4),
        border: Border.all(
          color: AppColors.dangerRed.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.dangerRed.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL GASTOS',
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          balanceAsync.when(
            loading: () => const LoadingSpinner(size: 28, strokeWidth: 2.5),
            error: (_, __) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'S/. —',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mutedText,
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(balanceProvider),
                  child: const Text('No se pudo cargar el saldo. Reintentar'),
                ),
              ],
            ),
            data: (balance) => Text(
              formatMonto(-balance.totalGastos),
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: AppColors.dangerRed,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Período: $filter',
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGastoItem(BuildContext context, Registro registro, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index * 80)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.dangerRed.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_upward_rounded,
                color: AppColors.dangerRed,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
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
            MontoText(
              monto: registro.monto,
              isIngreso: false,
              showSign: true,
            ),
            IconButton(
              tooltip: 'Editar registro',
              icon: const Icon(Icons.edit_outlined, color: AppColors.accentPurple, size: 20),
              onPressed: registro.id == null ? null : () => showAddEntryModal(context, type: 'gasto', record: registro),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, VoidCallback onRetry) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.dangerRed, size: 36),
          const SizedBox(height: AppSpacing.sm),
          Text('Error al cargar gastos',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.mutedText)),
          TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar',
                style: TextStyle(color: AppColors.accentPurple)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded,
              color: AppColors.mutedPurple.withOpacity(0.4), size: 48),
          const SizedBox(height: AppSpacing.sm),
          Text('Aún no hay registros',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.mutedText)),
        ],
      ),
    );
  }
}
