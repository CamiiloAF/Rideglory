import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class EventDetailStartedBanner extends StatelessWidget {
  const EventDetailStartedBanner({super.key, this.onFollowLive});

  final VoidCallback? onFollowLive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    context.l10n.event_eventLiveNow,
                    style: TextStyle(
                      color: context.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,
            Text(
              context.l10n.event_eventHasStartedTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            AppSpacing.gapSm,
            Text(
              context.l10n.event_eventHasStartedDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (onFollowLive != null) ...[
              AppSpacing.gapLg,
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: context.l10n.event_followRideLive,
                  icon: Icons.sensors,
                  onPressed: onFollowLive,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
