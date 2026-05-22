import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:rideglory/design_system/design_system.dart';

class WaypointItemCard extends StatelessWidget {
  const WaypointItemCard({
    super.key,
    required this.index,
    required this.name,
    required this.onDelete,
  });

  final int index;
  final String name;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Row(
        children: [
          _NumberBadge(number: index + 1),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                color: AppColors.textOnDarkPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                LucideIcons.x,
                size: 16,
                color: AppColors.textOnDarkTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number});

  final int number;

  Color get _color {
    if (number == 1) return AppColors.success;
    if (number == 9) return AppColors.error;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
