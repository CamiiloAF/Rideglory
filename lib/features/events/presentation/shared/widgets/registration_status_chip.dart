import 'package:flutter/material.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/design_system/design_system.dart';

class RegistrationStatusChip extends StatelessWidget {
  final RegistrationStatus status;

  const RegistrationStatusChip({super.key, required this.status});

  static Color _backgroundColor(
    BuildContext context,
    RegistrationStatus status,
  ) =>
      switch (status) {
        RegistrationStatus.pending => context.appColors.warning,
        RegistrationStatus.approved => context.appColors.success,
        RegistrationStatus.rejected => context.colorScheme.error,
        RegistrationStatus.cancelled => context.colorScheme.onSurfaceVariant,
        RegistrationStatus.readyForEdit => context.appColors.info,
      };

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _backgroundColor(context, status);
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
