import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/constants/registration_strings.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/registration/detail/widgets/registration_detail_info_row.dart';
import 'package:rideglory/features/events/presentation/registration/detail/widgets/registration_detail_section.dart';
import 'package:rideglory/features/events/presentation/shared/widgets/registration_status_chip.dart';
import 'package:rideglory/shared/widgets/app_app_bar.dart';
import 'package:rideglory/shared/widgets/modals/app_dialog.dart';
import 'package:rideglory/shared/widgets/modals/confirmation_dialog.dart';
import 'package:rideglory/shared/widgets/modals/dialog_type.dart';

class RegistrationDetailPage extends StatelessWidget {
  final EventRegistrationModel registration;
  final Future<bool> Function()? onCancelRegistration;

  const RegistrationDetailPage({
    super.key,
    required this.registration,
    this.onCancelRegistration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppAppBar(title: RegistrationStrings.registrationDetail),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    registration.eventId,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                RegistrationStatusChip(status: registration.status),
              ],
            ),
            if (registration.createdDate != null) ...[
              const SizedBox(height: 4),
              Text(
                '${RegistrationStrings.inscriptionDate}: ${DateFormat('d MMMM yyyy', 'es').format(registration.createdDate!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
            const SizedBox(height: 24),
            RegistrationDetailSection(
              title: RegistrationStrings.personalInfo,
              icon: Icons.person_outline,
              children: [
                RegistrationDetailInfoRow(
                  RegistrationStrings.firstName,
                  registration.firstName,
                ),
                RegistrationDetailInfoRow(
                  RegistrationStrings.lastName,
                  registration.lastName,
                ),
                RegistrationDetailInfoRow(
                  RegistrationStrings.identificationNumber,
                  registration.identificationNumber,
                ),
                RegistrationDetailInfoRow(
                  RegistrationStrings.birthDate,
                  DateFormat('d MMM yyyy', 'es').format(registration.birthDate),
                ),
                RegistrationDetailInfoRow(
                  RegistrationStrings.phone,
                  registration.phone,
                ),
                RegistrationDetailInfoRow(
                  RegistrationStrings.email,
                  registration.email,
                ),
                RegistrationDetailInfoRow(
                  RegistrationStrings.residenceCity,
                  registration.residenceCity,
                ),
              ],
            ),
            const SizedBox(height: 16),
            RegistrationDetailSection(
              title: RegistrationStrings.medicalInfo,
              icon: Icons.medical_services_outlined,
              children: [
                RegistrationDetailInfoRow(
                  RegistrationStrings.eps,
                  registration.eps,
                ),
                if (registration.medicalInsurance != null)
                  RegistrationDetailInfoRow(
                    RegistrationStrings.medicalInsurance,
                    registration.medicalInsurance!,
                  ),
                RegistrationDetailInfoRow(
                  RegistrationStrings.bloodType,
                  registration.bloodType.label,
                ),
              ],
            ),
            const SizedBox(height: 16),
            RegistrationDetailSection(
              title: RegistrationStrings.emergencyContact,
              icon: Icons.emergency_outlined,
              children: [
                RegistrationDetailInfoRow(
                  RegistrationStrings.emergencyContactName,
                  registration.emergencyContactName,
                ),
                RegistrationDetailInfoRow(
                  RegistrationStrings.emergencyContactPhone,
                  registration.emergencyContactPhone,
                ),
              ],
            ),
            const SizedBox(height: 16),
            RegistrationDetailSection(
              title: RegistrationStrings.vehicleInfo,
              icon: Icons.directions_bike_outlined,
              children: [
                RegistrationDetailInfoRow(
                  RegistrationStrings.vehicleBrand,
                  registration.vehicleBrand,
                ),
                RegistrationDetailInfoRow(
                  RegistrationStrings.vehicleReference,
                  registration.vehicleReference,
                ),
                RegistrationDetailInfoRow(
                  RegistrationStrings.licensePlate,
                  registration.licensePlate,
                ),
                if (registration.vin != null)
                  RegistrationDetailInfoRow(
                    RegistrationStrings.vin,
                    registration.vin!,
                  ),
              ],
            ),
            if (onCancelRegistration != null &&
                (registration.status == RegistrationStatus.pending ||
                    registration.status == RegistrationStatus.approved)) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _handleCancel(context),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text(EventStrings.cancelRegistration),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleCancel(BuildContext context) async {
    var confirmed = false;
    await ConfirmationDialog.show(
      context: context,
      title: EventStrings.cancelRegistrationTitle,
      content: EventStrings.cancelRegistrationMessage,
      dialogType: DialogType.warning,
      confirmLabel: AppStrings.accept,
      confirmType: DialogActionType.danger,
      onConfirm: () {
        confirmed = true;
      },
    );
    if (!confirmed || !context.mounted) return;
    final success = await onCancelRegistration!();
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(EventStrings.cancelRegistrationSuccess),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    }
  }
}
