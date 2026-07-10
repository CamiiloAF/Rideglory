import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/shared/widgets/form/app_switch_tile.dart';

class DeleteAccountUnderstandSwitch extends StatelessWidget {
  const DeleteAccountUnderstandSwitch({super.key, required this.onChanged});

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: AppSwitchTile(
        name: 'understandIrreversible',
        title: context.l10n.profile_deleteAccount_irreversibleSwitchLabel,
        onChanged: onChanged,
      ),
    );
  }
}
