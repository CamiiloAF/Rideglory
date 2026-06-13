import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class PriceSectionHeader extends StatelessWidget {
  const PriceSectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.l10n.event_form_price_section_title,
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: AppColors.textOnDarkTertiary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.darkTertiary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            context.l10n.event_form_optional_badge,
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textOnDarkTertiary,
            ),
          ),
        ),
      ],
    );
  }
}
