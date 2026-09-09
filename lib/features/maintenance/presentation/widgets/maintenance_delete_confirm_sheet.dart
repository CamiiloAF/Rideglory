import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/components/app_secondary_button.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Confirmación de borrado del detalle (Pencil `eRpHn`). El botón
/// destructivo usa `errorSolid` (nunca el acento de marca), vía
/// `AppPrimaryButton(destructive: true)`.
class MaintenanceDeleteConfirmSheet extends StatelessWidget {
  const MaintenanceDeleteConfirmSheet({
    required this.body,
    required this.onConfirm,
    super.key,
  });

  final String body;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.errorSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.trash2,
                size: 24,
                color: colors.errorText,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.maintenance_delete_confirm_title,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            AppPrimaryButton(
              label: l10n.maintenance_delete_confirm_action,
              onPressed: onConfirm,
              destructive: true,
            ),
            const SizedBox(height: 10),
            AppSecondaryButton(
              label: l10n.maintenance_delete_confirm_cancel,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
