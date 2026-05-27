import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// LIVE + APPROVED USER: full-width orange "Seguir rodada en vivo" button.
class EventDetailLiveUserBar extends StatelessWidget {
  const EventDetailLiveUserBar({super.key, required this.onFollowLive});

  final VoidCallback onFollowLive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onFollowLive,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.navigation_rounded,
              color: AppColors.darkBgPrimary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              context.l10n.event_followRideLive,
              style: const TextStyle(
                color: AppColors.darkBgPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
