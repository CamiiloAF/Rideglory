import 'package:flutter/material.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';

class RegistrationStatusChip extends StatelessWidget {
  final RegistrationStatus status;

  const RegistrationStatusChip({super.key, required this.status});

  static Color colorForStatus(RegistrationStatus status) => switch (status) {
    RegistrationStatus.pending => Colors.orange,
    RegistrationStatus.approved => Colors.green,
    RegistrationStatus.rejected => Colors.red,
    RegistrationStatus.cancelled => Colors.grey,
    RegistrationStatus.readyForEdit => Colors.blue,
  };

  @override
  Widget build(BuildContext context) {
    final color = colorForStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
