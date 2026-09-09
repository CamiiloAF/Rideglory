import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../design_system/components/app_primary_button.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../l10n/l10n_extensions.dart';

/// Estado vacío obligatorio: sin datos, pero sin pantalla en blanco.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    this.title,
    this.body,
    this.icon = LucideIcons.calendarDays,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    super.key,
  });

  final String? title;
  final String? body;
  final IconData icon;

  /// Si se provee junto a [onAction], agrega un `AppPrimaryButton` debajo
  /// del cuerpo (ej. "Registrar mantenimiento").
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: colors.textSecondary),
            const SizedBox(height: 16),
            Text(
              title ?? context.l10n.common_empty_title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: colors.textSecondary),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              AppPrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                icon: actionIcon,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
