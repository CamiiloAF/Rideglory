import 'package:flutter/material.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';

// TODO mejorar widgets y reutilizar los existentes
class EventsEmptyWidget extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final VoidCallback onCreatePressed;

  const EventsEmptyWidget({
    super.key,
    required this.onRefresh,
    required this.onCreatePressed,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  EventStrings.noEvents,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    EventStrings.noEventsDescription,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onCreatePressed,
                  icon: const Icon(Icons.add),
                  label: const Text(EventStrings.createEvent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
          FilledButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class EventNoSearchResultsWidget extends StatelessWidget {
  const EventNoSearchResultsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin resultados',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otros filtros o términos de búsqueda',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
