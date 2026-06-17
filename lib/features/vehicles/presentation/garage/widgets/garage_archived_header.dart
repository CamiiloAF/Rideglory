import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class GarageArchivedHeader extends StatelessWidget {
  const GarageArchivedHeader({
    super.key,
    required this.count,
    required this.isExpanded,
    required this.onTap,
  });

  final int count;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: isExpanded
                  ? context.colorScheme.primary
                  : AppColors.textOnDarkSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            context.l10n.vehicle_archivedSection,
            style: TextStyle(
              color: isExpanded
                  ? context.colorScheme.primary
                  : AppColors.textOnDarkSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorderPrimary),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: AppColors.textOnDarkSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
            size: 20,
            color: AppColors.textOnDarkSecondary,
          ),
        ],
      ),
    );
  }
}
