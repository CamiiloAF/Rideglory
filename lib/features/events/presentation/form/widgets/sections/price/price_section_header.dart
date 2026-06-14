import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class PriceSectionHeader extends StatelessWidget {
  const PriceSectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      context.l10n.event_form_price_section_title,
      style: const TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: AppColors.textOnDarkTertiary,
      ),
    );
  }
}
