import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/utils/spanish_date_format.dart';
import '../../../../core/utils/thousands_input_formatter.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_radii.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/maintenance.dart';

/// Hoja de acciones del detalle: editar o eliminar (Pencil `yZ3We`).
class MaintenanceActionsSheet extends StatelessWidget {
  const MaintenanceActionsSheet({
    required this.maintenance,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Maintenance maintenance;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
            Text(
              maintenance.type,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            Text(
              '${SpanishDateFormat.short(maintenance.serviceDate)} · '
              '${l10n.maintenance_value_km(ThousandsInputFormatter.format(maintenance.odometer) ?? '${maintenance.odometer}')}',
              style: TextStyle(fontSize: 13.5, color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: colors.borderStrong),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.pencil, size: 19, color: colors.text),
                    const SizedBox(width: 12),
                    Text(
                      l10n.maintenance_actions_sheet_edit,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: colors.borderStrong),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.trash2, size: 19, color: colors.errorText),
                    const SizedBox(width: 12),
                    Text(
                      l10n.maintenance_actions_sheet_delete,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: colors.errorText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
