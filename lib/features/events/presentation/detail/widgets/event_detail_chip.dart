import 'package:flutter/material.dart';

class EventDetailChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSolid;

  const EventDetailChip({
    super.key,
    required this.label,
    required this.color,
    this.isSolid = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSolid ? color : color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSolid ? color : color.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isSolid ? Colors.white : color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
