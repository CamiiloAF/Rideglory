import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

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
          color: context.appColors.eventFree.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          context.l10n.event_free,
          style: theme.textTheme.labelSmall?.copyWith(
            color: context.appColors.eventFree,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.appColors.eventPaid.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '\$${price!.toStringAsFixed(0)}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: context.appColors.eventPaid,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
