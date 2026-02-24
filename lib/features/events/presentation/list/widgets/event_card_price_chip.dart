import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';

class EventCardPriceChip extends StatelessWidget {
  final bool isFree;
  final double? price;

  const EventCardPriceChip({super.key, required this.isFree, this.price});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isFree) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.eventFree.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          EventStrings.free,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.eventFree,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.eventPaid.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '\$${price!.toStringAsFixed(0)}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppColors.eventPaid,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
