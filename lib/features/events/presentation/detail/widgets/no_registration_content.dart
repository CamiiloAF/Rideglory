import 'package:flutter/material.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

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
        FilledButton.icon(
          onPressed: onRegister,
          icon: const Icon(Icons.how_to_reg_outlined),
          label: const Text(EventStrings.joinEvent),
        ),
        if (onViewRecommendations != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onViewRecommendations,
            icon: const Icon(Icons.tips_and_updates_outlined),
            label: const Text(EventStrings.viewRecommendations),
          ),
        ],
      ],
    );
  }
}
