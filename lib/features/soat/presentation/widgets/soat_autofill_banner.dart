import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Banner shown atop the SOAT form when the scan detected a valid SOAT. Lets the
/// user opt in to filling the fields with the detected data instead of doing it
/// automatically, so they stay in control and review before saving.
class SoatAutofillBanner extends StatelessWidget {
  const SoatAutofillBanner({super.key, required this.onAutofill});

  final VoidCallback onAutofill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_fix_high_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.soat_autofill_banner_title,
                      style: const TextStyle(
                        color: AppColors.textOnDarkPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.soat_autofill_banner_subtitle,
                      style: const TextStyle(
                        color: AppColors.textOnDarkSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppButton(
            label: context.l10n.soat_autofill_banner_button,
            icon: Icons.auto_fix_high_rounded,
            onPressed: onAutofill,
            shape: AppButtonShape.pill,
            height: 44,
          ),
        ],
      ),
    );
  }
}
