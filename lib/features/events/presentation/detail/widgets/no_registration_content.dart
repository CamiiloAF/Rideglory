import 'package:flutter/material.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/design_system/design_system.dart';

class NoRegistrationContent extends StatelessWidget {
  final EventModel event;
  final VoidCallback onRegister;

  const NoRegistrationContent({
    super.key,
    required this.event,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          EventStrings.joinEvent,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          event.isFree
              ? EventStrings.free
              : '\$${event.price!.toStringAsFixed(0)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
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
