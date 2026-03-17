import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';

class RegistrationStatusChip extends StatelessWidget {
  final RegistrationStatus status;

  const RegistrationStatusChip({super.key, required this.status});

  static Color _backgroundColor(RegistrationStatus status) => switch (status) {
    RegistrationStatus.pending => AppColors.warning,
    RegistrationStatus.approved => AppColors.success,
    RegistrationStatus.rejected => AppColors.error,
    RegistrationStatus.cancelled => AppColors.darkTextSecondary,
    RegistrationStatus.readyForEdit => AppColors.info,
  };

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _backgroundColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
