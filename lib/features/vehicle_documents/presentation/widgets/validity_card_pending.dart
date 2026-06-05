import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Card rendered inside [DocumentValidityCard] when dates are not yet set.
class ValidityCardPending extends StatelessWidget {
  const ValidityCardPending({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkTertiary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 20,
            color: AppColors.textOnDarkTertiary,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textOnDarkTertiary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
