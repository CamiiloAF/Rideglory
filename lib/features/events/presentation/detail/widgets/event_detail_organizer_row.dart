import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

class EventDetailOrganizerRow extends StatelessWidget {
  const EventDetailOrganizerRow({
    super.key,
    required this.organizerName,
  });

  final String organizerName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: context.colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(Icons.check, color: Colors.white, size: 14),
        ),
        SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: context.colorScheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              children: [
                const TextSpan(text: '${EventStrings.organizedBy} '),
                TextSpan(
                  text: organizerName,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
