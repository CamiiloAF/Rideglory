import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/save_maintenance_button.dart';

class MaintenanceFormCtaBar extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  const MaintenanceFormCtaBar({
    super.key,
    required this.onSave,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.darkBgPrimary,
        border: Border(top: BorderSide(color: AppColors.darkBorderPrimary)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SaveMaintenanceButton(onSave: onSave),
          const SizedBox(height: 10),
          AppTextButton(
            label: context.l10n.maintenance_form_discard,
            onPressed: onDiscard,
            variant: AppTextButtonVariant.muted,
          ),
        ],
      ),
    );
  }
}
