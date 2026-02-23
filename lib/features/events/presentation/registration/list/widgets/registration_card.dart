import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/constants/registration_strings.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/registration/list/my_registrations_cubit.dart';
import 'package:rideglory/features/events/presentation/shared/dialogs/cancel_registration_dialog.dart';
import 'package:rideglory/features/events/presentation/shared/widgets/registration_status_chip.dart';
import 'package:rideglory/shared/widgets/info_chip.dart';

class RegistrationCard extends StatelessWidget {
  final EventRegistrationModel registration;
  final VoidCallback? onViewDetails;
  final VoidCallback? onViewEvent;

  const RegistrationCard({
    super.key,
    required this.registration,
    this.onViewDetails,
    this.onViewEvent,
  });

  static String _statusDescription(RegistrationStatus status) =>
      switch (status) {
        RegistrationStatus.pending => EventStrings.pendingDescription,
        RegistrationStatus.approved => EventStrings.approvedDescription,
        RegistrationStatus.rejected => EventStrings.rejectedDescription,
        RegistrationStatus.cancelled => EventStrings.cancelledDescription,
        RegistrationStatus.readyForEdit => EventStrings.readyForEditDescription,
      };

  Future<void> _confirmCancel(BuildContext context) =>
      CancelRegistrationDialog.showAndExecute(
        context: context,
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
    final canCancel =
        registration.status == RegistrationStatus.pending ||
        registration.status == RegistrationStatus.approved;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.10),
            blurRadius: 10,
            spreadRadius: -2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onViewDetails,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: title/status + popup menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            registration.registrationTitle,
                            style: context.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          RegistrationStatusChip(status: registration.status),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: Colors.grey[600],
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'event',
                          child: Row(
                            children: [
                              Icon(
                                Icons.event_outlined,
                                size: 20,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(width: 12),
                              const Text(RegistrationStrings.viewEvent),
                            ],
                          ),
                        ),
                        if (canCancel)
                          const PopupMenuItem(
                            value: 'cancel',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.cancel_outlined,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  EventStrings.cancelRegistration,
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                      ],
                      onSelected: (v) {
                        if (v == 'event') onViewEvent?.call();
                        if (v == 'cancel') _confirmCancel(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Info chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    InfoChip(
                      icon: Icons.two_wheeler_outlined,
                      label:
                          '${registration.vehicleBrand} ${registration.vehicleReference}',
                      color: const Color(0xFF6366F1),
                    ),
                    InfoChip(
                      icon: Icons.badge_rounded,
                      label: registration.licensePlate,
                      color: const Color(0xFFF59E0B),
                    ),
                    if (registration.createdDate != null)
                      InfoChip(
                        icon: Icons.calendar_today_rounded,
                        label: DateFormat(
                          'd MMM yyyy',
                          'es',
                        ).format(registration.createdDate!),
                        color: const Color(0xFF10B981),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Status description
                Text(
                  _statusDescription(registration.status),
                  style: context.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
