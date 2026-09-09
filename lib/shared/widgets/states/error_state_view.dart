import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../design_system/components/app_secondary_button.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../l10n/l10n_extensions.dart';

/// Estado de error accionable: mensaje en español llano y botón de
/// reintentar. Nunca un error mudo.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    required this.onRetry,
    this.title,
    this.message,
    super.key,
  });

  final VoidCallback onRetry;
  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertTriangle, size: 40, color: colors.error),
            const SizedBox(height: 16),
            Text(
              title ?? context.l10n.common_error_title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? context.l10n.common_error_body,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
            AppSecondaryButton(
              label: context.l10n.common_retry,
              onPressed: onRetry,
              icon: LucideIcons.refreshCw,
            ),
          ],
        ),
      ),
    );
  }
}
