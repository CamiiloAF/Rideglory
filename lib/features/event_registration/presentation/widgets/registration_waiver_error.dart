import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Inline error block for the risk-waiver sheet. Differentiates the underage
/// case from any other server/local error, which falls back to the raw message.
class RegistrationWaiverError extends StatelessWidget {
  const RegistrationWaiverError({
    super.key,
    required this.isUnderage,
    required this.message,
  });

  final bool isUnderage;
  final String message;

  @override
  Widget build(BuildContext context) {
    if (isUnderage) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.registration_underageTitle,
            style: const TextStyle(
              color: AppColors.error,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          AppSpacing.gapXxs,
          Text(
            context.l10n.registration_underageMessage,
            style: const TextStyle(
              color: AppColors.textOnDarkSecondary,
              fontSize: 13,
            ),
          ),
        ],
      );
    }

    return Text(
      message,
      style: const TextStyle(
        color: AppColors.error,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
