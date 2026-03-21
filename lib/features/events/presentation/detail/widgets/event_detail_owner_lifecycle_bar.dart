import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class EventDetailOwnerLifecycleBar extends StatelessWidget {
  const EventDetailOwnerLifecycleBar({
    super.key,
    required this.event,
    required this.isLoading,
    required this.onStart,
    required this.onStop,
  });

  final EventModel event;
  final bool isLoading;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(
          top: BorderSide(color: context.colorScheme.outlineVariant),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, max(16.0, bottomPadding)),
      child: switch (event.state) {
        EventState.scheduled => AppButton(
            label: context.l10n.event_startEvent,
            isFullWidth: true,
            isLoading: isLoading,
            onPressed: isLoading ? null : onStart,
          ),
        EventState.inProgress => AppButton(
            label: context.l10n.event_stopEvent,
            isFullWidth: true,
            isLoading: isLoading,
            variant: AppButtonVariant.danger,
            style: AppButtonStyle.filled,
            onPressed: isLoading ? null : onStop,
          ),
        EventState.finished => const SizedBox.shrink(),
        EventState.cancelled => const SizedBox.shrink(),
      },
    );
  }
}
