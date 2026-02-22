import 'package:flutter/material.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';
import 'package:rideglory/shared/widgets/form/app_text_button.dart';

class NoRegistrationContent extends StatelessWidget {
  final EventModel event;
  final VoidCallback onRegister;
  final VoidCallback? onViewRecommendations;

  const NoRegistrationContent({
    super.key,
    required this.event,
    required this.onRegister,
    this.onViewRecommendations,
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
        const SizedBox(height: 4),
        Text(
          event.isFree
              ? EventStrings.free
              : '\$${event.price!.toStringAsFixed(0)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: EventStrings.joinEvent,
          onPressed: onRegister,
          icon: Icons.how_to_reg_outlined,
        ),
        if (onViewRecommendations != null) ...[
          const SizedBox(height: 8),
          AppTextButton(
            label: EventStrings.viewRecommendations,
            onPressed: onViewRecommendations,
            icon: Icons.tips_and_updates_outlined,
          ),
        ],
      ],
    );
  }
}
