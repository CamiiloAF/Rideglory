import 'package:flutter/material.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/shared/widgets/registration_status_chip.dart';
import 'package:rideglory/design_system/design_system.dart';

class CancelledRegistrationContent extends StatelessWidget {
  final VoidCallback onRegister;

  const CancelledRegistrationContent({super.key, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            RegistrationStatusChip(status: RegistrationStatus.cancelled),
          ],
        ),
        SizedBox(height: 8),
        Text(
          EventStrings.cancelledDescription,
          style: theme.textTheme.bodySmall,
        ),
        SizedBox(height: 12),
        AppButton(
          label: EventStrings.joinEvent,
          onPressed: onRegister,
          icon: Icons.how_to_reg_outlined,
        ),
      ],
    );
  }
}
