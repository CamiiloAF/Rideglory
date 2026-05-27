import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class MultiBrandToggleCard extends StatelessWidget {
  const MultiBrandToggleCard({
    super.key,
    required this.isMultiBrand,
    required this.onChanged,
  });

  final bool isMultiBrand;
  final void Function(bool?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.event_multiBrandLabel,
                style: const TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textOnDarkPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isMultiBrand
                    ? context.l10n.event_multiBrandAllowAny
                    : context.l10n.event_selectBrands,
                style: const TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                  color: AppColors.textOnDarkTertiary,
                ),
              ),
            ],
          ),
          Switch(
            value: isMultiBrand,
            onChanged: onChanged,
            activeThumbColor: Colors.black,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
