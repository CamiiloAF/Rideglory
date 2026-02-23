import 'package:flutter/material.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/cancelled_registration_content.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/no_registration_content.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/registration_status_content.dart';

class EventRegistrationStatusCard extends StatelessWidget {
  final EventModel event;
  final EventRegistrationModel? registration;
  final VoidCallback onRegister;
  final VoidCallback? onEditRegistration;
  final VoidCallback? onCancelRegistration;
  final VoidCallback? onViewRecommendations;

  const EventRegistrationStatusCard({
    super.key,
    required this.event,
    required this.registration,
    required this.onRegister,
    this.onEditRegistration,
    this.onCancelRegistration,
    this.onViewRecommendations,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (registration == null) {
      return NoRegistrationContent(
        event: event,
        onRegister: onRegister,
        onViewRecommendations: onViewRecommendations,
      );
    }

    return switch (registration!.status) {
      RegistrationStatus.pending => RegistrationStatusContent(
        status: registration!.status,
        description: EventStrings.pendingDescription,
        onCancel: onCancelRegistration,
        onViewRecommendations: onViewRecommendations,
      ),
      RegistrationStatus.approved => RegistrationStatusContent(
        status: registration!.status,
        description: EventStrings.approvedDescription,
        onCancel: onCancelRegistration,
        onViewRecommendations: onViewRecommendations,
      ),
      RegistrationStatus.rejected => RegistrationStatusContent(
        status: registration!.status,
        description: EventStrings.rejectedDescription,
      ),
      RegistrationStatus.cancelled => CancelledRegistrationContent(
        onRegister: onRegister,
      ),
      RegistrationStatus.readyForEdit => RegistrationStatusContent(
        status: registration!.status,
        description: EventStrings.readyForEditDescription,
        onEdit: onEditRegistration,
        onViewRecommendations: onViewRecommendations,
      ),
    };
  }
}
