import 'package:flutter/material.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';

// TODO mejorar widgets y reutilizar los existentes

class EventsLoadingWidget extends StatelessWidget {
  const EventsLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
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
          const SizedBox(height: 16),
          Text(
            EventStrings.errorLoadingEvents,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
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
