import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/attendees/attendees_cubit.dart';
import 'package:rideglory/features/events/presentation/attendees/widgets/attendee_action_button.dart';
import 'package:rideglory/features/events/presentation/attendees/widgets/attendee_contact_button.dart';
import 'package:rideglory/features/events/presentation/shared/widgets/registration_status_chip.dart';
import 'package:rideglory/shared/widgets/modals/confirmation_dialog.dart';
import 'package:rideglory/shared/widgets/modals/dialog_type.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

class AttendeeCard extends StatelessWidget {
  final EventRegistrationModel registration;

  const AttendeeCard({super.key, required this.registration});

  static Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await launcher.canLaunchUrl(uri)) {
      await launcher.launchUrl(
        uri,
        mode: launcher.LaunchMode.externalApplication,
      );
    }
  }

  static String sanitizePhone(String phone) =>
      phone.replaceAll(RegExp(r'[^\d+]'), '');

  Future<void> _confirmAction(
    BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) => ConfirmationDialog.show(
    context: context,
    title: title,
    content: content,
    dialogType: DialogType.warning,
    confirmLabel: title,
    onConfirm: onConfirm,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
                      '${registration.firstName} ${registration.lastName}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${registration.vehicleBrand} ${registration.vehicleReference} · ${registration.licensePlate}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              RegistrationStatusChip(status: registration.status),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              AttendeeContactButton(
                icon: Icons.phone_outlined,
                label: EventStrings.callAttendee,
                onPressed: () => openUrl('tel:${registration.phone}'),
              ),
              AttendeeContactButton(
                icon: Icons.email_outlined,
                label: EventStrings.emailAttendee,
                onPressed: () => openUrl('mailto:${registration.email}'),
              ),
              AttendeeContactButton(
                icon: Icons.chat_outlined,
                label: EventStrings.whatsappAttendee,
                onPressed: () => openUrl(
                  'https://wa.me/${sanitizePhone(registration.phone)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              if (registration.status == RegistrationStatus.pending ||
                  registration.status == RegistrationStatus.readyForEdit)
                AttendeeActionButton(
                  label: EventStrings.approveRegistration,
                  color: Colors.green,
                  onPressed: () => _confirmAction(
                    context,
                    title: EventStrings.approveRegistration,
                    content: EventStrings.approveConfirmMessage(
                      registration.firstName,
                    ),
                    onConfirm: () => context
                        .read<AttendeesCubit>()
                        .approveRegistration(registration.id!),
                  ),
                ),
              if (registration.status == RegistrationStatus.pending ||
                  registration.status == RegistrationStatus.approved)
                AttendeeActionButton(
                  label: EventStrings.rejectRegistration,
                  color: Colors.red,
                  onPressed: () => _confirmAction(
                    context,
                    title: EventStrings.rejectRegistration,
                    content: EventStrings.rejectConfirmMessage(
                      registration.firstName,
                    ),
                    onConfirm: () => context
                        .read<AttendeesCubit>()
                        .rejectRegistration(registration.id!),
                  ),
                ),
              if (registration.status == RegistrationStatus.approved)
                AttendeeActionButton(
                  label: EventStrings.setReadyForEdit,
                  color: Colors.blue,
                  onPressed: () => _confirmAction(
                    context,
                    title: EventStrings.setReadyForEdit,
                    content: EventStrings.setReadyForEditConfirmMessage(
                      registration.firstName,
                    ),
                    onConfirm: () => context
                        .read<AttendeesCubit>()
                        .setReadyForEdit(registration.id!),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
