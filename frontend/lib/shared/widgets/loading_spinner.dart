import 'package:flutter/material.dart';
import 'package:gastos_claros/core/theme.dart';

/// Spinner de carga dinámico reutilizable.
/// Se usa en todas las pantallas cuando hay procesos asíncronos.
class LoadingSpinner extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final String? message;

  const LoadingSpinner({
    super.key,
    this.size = 36,
    this.strokeWidth = 3.0,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accentPurple,
              ),
              strokeWidth: strokeWidth,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
