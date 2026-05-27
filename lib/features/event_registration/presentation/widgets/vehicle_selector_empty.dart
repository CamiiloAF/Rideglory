import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleSelectorEmpty extends StatelessWidget {
  const VehicleSelectorEmpty({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.registration_vehicleEmptyStateTitle,
          style: context.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        AppSpacing.gapMd,
        AppButton(
          label: context.l10n.registration_createVehicleCta,
          onPressed: onCreate,
          style: AppButtonStyle.outlined,
        ),
      ],
    );
  }
}
