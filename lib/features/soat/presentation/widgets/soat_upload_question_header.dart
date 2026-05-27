import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class SoatUploadQuestionHeader extends StatelessWidget {
  const SoatUploadQuestionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.vehicle_soat_upload_question,
          style: const TextStyle(
            color: AppColors.textOnDarkPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.vehicle_soat_upload_subtitle,
          style: const TextStyle(
            color: AppColors.textOnDarkSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
