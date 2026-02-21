import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/registration/list/my_registrations_cubit.dart';
import 'package:rideglory/features/events/presentation/shared/widgets/registration_status_chip.dart';
import 'package:rideglory/shared/widgets/modals/app_dialog.dart';
import 'package:rideglory/shared/widgets/modals/confirmation_dialog.dart';
import 'package:rideglory/shared/widgets/modals/dialog_type.dart';

class RegistrationCard extends StatelessWidget {
  final EventRegistrationModel registration;

  const RegistrationCard({super.key, required this.registration});

  static String statusDescription(RegistrationStatus status) =>
      switch (status) {
        RegistrationStatus.pending => EventStrings.pendingDescription,
        RegistrationStatus.approved => EventStrings.approvedDescription,
        RegistrationStatus.rejected => EventStrings.rejectedDescription,
        RegistrationStatus.cancelled => EventStrings.cancelledDescription,
        RegistrationStatus.readyForEdit => EventStrings.readyForEditDescription,
      };

  Future<void> _confirmCancel(BuildContext context) => ConfirmationDialog.show(
    context: context,
    title: EventStrings.cancelRegistrationTitle,
    content: EventStrings.cancelRegistrationMessage,
    dialogType: DialogType.warning,
    confirmLabel: EventStrings.cancelRegistration,
    confirmType: DialogActionType.danger,
    onConfirm: () {
      if (registration.id != null) {
        context.read<MyRegistrationsCubit>().cancelRegistration(
          registration.id!,
        );
      }
    },
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        registration.eventId,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (registration.createdDate != null)
                        Text(
                          DateFormat(
                            'd MMM yyyy',
                            'es',
                          ).format(registration.createdDate!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ),
                RegistrationStatusChip(status: registration.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${registration.vehicleBrand} ${registration.vehicleReference} · ${registration.licensePlate}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              statusDescription(registration.status),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            if (registration.status == RegistrationStatus.pending ||
                registration.status == RegistrationStatus.approved) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _confirmCancel(context),
                  icon: const Icon(Icons.cancel_outlined),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: EdgeInsets.zero,
                  ),
                  label: const Text(EventStrings.cancelRegistration),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
