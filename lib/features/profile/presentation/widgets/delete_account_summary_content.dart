import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/delete_account_summary.dart';

/// Titular, subtexto, lista de lo que se borra y el aviso de "solo quieres
/// salir" del paso 1 de borrar cuenta.
///
/// Pencil: MCSBy
class DeleteAccountSummaryContent extends StatelessWidget {
  const DeleteAccountSummaryContent({required this.summary, super.key});

  final DeleteAccountSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final items = <(IconData, String)>[
      (
        LucideIcons.bike,
        context.l10n.profile_delete_item_vehicles(summary.vehicleCount),
      ),
      (
        LucideIcons.wrench,
        context.l10n.profile_delete_item_maintenances(summary.maintenanceCount),
      ),
      (
        LucideIcons.fileText,
        context.l10n.profile_delete_item_documents(summary.documentCount),
      ),
      (
        LucideIcons.calendarDays,
        context.l10n.profile_delete_item_registrations,
      ),
      (LucideIcons.user, context.l10n.profile_delete_item_profile),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.profile_delete_headline,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.profile_delete_subtext,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: colors.surface,
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) Container(height: 1, color: colors.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        Icon(items[i].$1, size: 18, color: colors.errorSolid),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            items[i].$2,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.info, size: 16, color: colors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.profile_delete_just_logout_title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.l10n.profile_delete_just_logout_body,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
