import 'package:flutter/material.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

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
          context.l10n.event_joinEvent,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        AppSpacing.gapXxs,
        Text(
          event.isFree
              ? context.l10n.event_free
              : '\$${event.price!.toStringAsFixed(0)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
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
