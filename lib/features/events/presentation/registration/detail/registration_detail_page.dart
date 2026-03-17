import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/events/constants/registration_strings.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/registration/detail/widgets/registration_detail_approve_reject_bar.dart';
import 'package:rideglory/features/events/presentation/registration/detail/widgets/registration_detail_cancel_bar.dart';
import 'package:rideglory/features/events/presentation/registration/detail/widgets/registration_detail_emergency_section.dart';
import 'package:rideglory/features/events/presentation/registration/detail/widgets/registration_detail_header.dart';
import 'package:rideglory/features/events/presentation/registration/detail/widgets/registration_detail_medical_section.dart';
import 'package:rideglory/features/events/presentation/registration/detail/widgets/registration_detail_personal_section.dart';
import 'package:rideglory/features/events/presentation/registration/detail/widgets/registration_detail_vehicle_section.dart';
import 'package:rideglory/features/events/presentation/shared/dialogs/cancel_registration_dialog.dart';
import 'package:rideglory/shared/widgets/app_app_bar.dart';

class RegistrationDetailPage extends StatelessWidget {
  const RegistrationDetailPage({
    super.key,
    required this.registration,
    this.onCancelRegistration,
    this.onApprove,
    this.onReject,
  });

  final EventRegistrationModel registration;
  final Future<bool> Function()? onCancelRegistration;
  final void Function(BuildContext context)? onApprove;
  final void Function(BuildContext context)? onReject;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(
        title: RegistrationStrings.registrationDetailTitle,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RegistrationDetailHeader(registration: registration),
            const SizedBox(height: 24),
            RegistrationDetailPersonalSection(registration: registration),
            const SizedBox(height: 24),
            RegistrationDetailMedicalSection(registration: registration),
            const SizedBox(height: 24),
            RegistrationDetailEmergencySection(registration: registration),
            const SizedBox(height: 24),
            RegistrationDetailVehicleSection(registration: registration),
          ],
        )
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  bool _showApproveRejectBar() => onReject != null && onApprove != null;

  Widget? _buildBottomBar(BuildContext context) {
    if (_showApproveRejectBar()) {
      return RegistrationDetailApproveRejectBar(
        onReject: () => onReject!(context),
        onApprove: () => onApprove!(context),
      );
    }

    if (onCancelRegistration != null &&
        (registration.status == RegistrationStatus.pending ||
            registration.status == RegistrationStatus.approved)) {
      return RegistrationDetailCancelBar(
        onCancel: () => _handleCancel(context),
      );
    }

    return null;
  }

  Future<void> _handleCancel(BuildContext context) async {
    final success = await CancelRegistrationDialog.show(
      context: context,
      onCancel: onCancelRegistration!,
    );
    if (success && context.mounted) {
      context.pop();
    }
  }
}
