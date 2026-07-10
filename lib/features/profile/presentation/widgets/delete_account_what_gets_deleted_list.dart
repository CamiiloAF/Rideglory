import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/profile/presentation/widgets/delete_account_list_row.dart';

class DeleteAccountWhatGetsDeletedList extends StatelessWidget {
  const DeleteAccountWhatGetsDeletedList({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.profile_deleteAccount_listLabel,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.textOnDarkTertiary,
          ),
        ),
        AppSpacing.gapMd,
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.darkBorderPrimary),
          ),
          child: Column(
            children: [
              DeleteAccountListRow(
                icon: Icons.person_outline,
                title: l10n.profile_deleteAccount_itemProfileTitle,
                description: l10n.profile_deleteAccount_itemProfileDesc,
              ),
              const Divider(height: 1, color: AppColors.darkBorderPrimary),
              DeleteAccountListRow(
                icon: Icons.two_wheeler_outlined,
                title: l10n.profile_deleteAccount_itemVehiclesTitle,
                description: l10n.profile_deleteAccount_itemVehiclesDesc,
              ),
              const Divider(height: 1, color: AppColors.darkBorderPrimary),
              DeleteAccountListRow(
                icon: Icons.build_outlined,
                title: l10n.profile_deleteAccount_itemMaintenanceTitle,
                description: l10n.profile_deleteAccount_itemMaintenanceDesc,
              ),
              const Divider(height: 1, color: AppColors.darkBorderPrimary),
              DeleteAccountListRow(
                icon: Icons.event_note_outlined,
                title: l10n.profile_deleteAccount_itemEventsTitle,
                description: l10n.profile_deleteAccount_itemEventsDesc,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
