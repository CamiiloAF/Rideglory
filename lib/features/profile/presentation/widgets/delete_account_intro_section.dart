import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class DeleteAccountIntroSection extends StatelessWidget {
  const DeleteAccountIntroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.errorSubtle,
            borderRadius: BorderRadius.circular(32),
          ),
          child: const Icon(
            Icons.delete_outline,
            color: AppColors.error,
            size: 32,
          ),
        ),
        AppSpacing.gapMd,
        Text(
          context.l10n.profile_deleteAccount_introTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textOnDarkPrimary,
          ),
        ),
        AppSpacing.gapMd,
        Text(
          context.l10n.profile_deleteAccount_introBody,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textOnDarkSecondary,
          ),
        ),
      ],
    );
  }
}
