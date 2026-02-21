import 'package:flutter/material.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/shared/widgets/registration_status_chip.dart';

class CancelledRegistrationContent extends StatelessWidget {
  final VoidCallback onRegister;

  const CancelledRegistrationContent({super.key, required this.onRegister});

  // TODO revisar row 18
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
        const SizedBox(height: 8),
        Text(
          EventStrings.cancelledDescription,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onRegister,
          icon: const Icon(Icons.how_to_reg_outlined),
          label: const Text(EventStrings.joinEvent),
        ),
      ],
    );
  }
}
