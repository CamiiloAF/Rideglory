import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class HomeNotificationButton extends StatelessWidget {
  const HomeNotificationButton({super.key, required this.showBadge});

  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colorScheme.outlineVariant),
          ),
          child: Icon(
            Icons.notifications_outlined,
            color: context.colorScheme.onSurface,
            size: 22,
          ),
        ),
        if (showBadge)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: context.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
