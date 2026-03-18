import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

// TODO mejorar widgets y reutilizar los existentes

class EventsLoadingWidget extends StatelessWidget {
  const EventsLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLoadingIndicator(variant: AppLoadingIndicatorVariant.page);
  }
}

class EventsErrorWidget extends StatelessWidget {
  final String message;
  final Future<void> Function() onRefresh;

  const EventsErrorWidget({
    super.key,
    required this.message,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          AppSpacing.gapLg,
          Text(
            context.l10n.event_errorLoadingEvents,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          AppSpacing.gapSm,
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          AppSpacing.gapLg,
          AppButton(
            label: 'Reintentar',
            onPressed: onRefresh,
            icon: Icons.refresh,
            isFullWidth: false,
          ),
        ],
      ),
    );
  }
}
