import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class EventFormSectionCard extends StatelessWidget {
  const EventFormSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: context.colorScheme.onSurface, size: 22),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: context.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}
