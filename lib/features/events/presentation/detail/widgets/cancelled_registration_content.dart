import 'package:flutter/material.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/shared/widgets/registration_status_chip.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class CancelledRegistrationContent extends StatelessWidget {
  final VoidCallback onRegister;

  const CancelledRegistrationContent({super.key, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            RegistrationStatusChip(status: RegistrationStatus.cancelled),
          ],
        ),
        AppSpacing.gapSm,
        Text(
          context.l10n.event_cancelledDescription,
          style: theme.textTheme.bodySmall,
        ),
        AppSpacing.gapMd,
        AppButton(
          label: context.l10n.event_joinEvent,
          onPressed: onRegister,
          icon: Icons.how_to_reg_outlined,
        ),
      ],
    );
  }
}
