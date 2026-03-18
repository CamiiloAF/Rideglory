import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';

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
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.darkBorder),
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
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    EventStrings.eventLiveNow,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              EventStrings.eventHasStartedTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              EventStrings.eventHasStartedDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (onFollowLive != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: EventStrings.followRideLive,
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
