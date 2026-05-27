import 'package:flutter/material.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_card_popup_menu.dart';

class EventCardHeader extends StatelessWidget {
  final String eventName;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EventCardHeader({
    super.key,
    required this.eventName,
    required this.isOwner,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            eventName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isOwner)
          EventCardPopupMenu(
            onEdit: onEdit,
            onDelete: onDelete,
          ),
      ],
    );
  }
}
