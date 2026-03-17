import 'package:flutter/material.dart';
import 'package:rideglory/features/events/constants/registration_strings.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/registration/detail/widgets/registration_detail_emergency_card.dart';
import 'package:rideglory/features/events/presentation/registration/detail/widgets/registration_detail_section.dart';

class RegistrationDetailEmergencySection extends StatelessWidget {
  const RegistrationDetailEmergencySection({
    super.key,
    required this.registration,
  });

  final EventRegistrationModel registration;

  @override
  Widget build(BuildContext context) {
    return RegistrationDetailSection(
      title: RegistrationStrings.emergencyContact,
      icon: Icons.shield_outlined,
      children: [
        RegistrationDetailEmergencyCard(
          contactName: registration.emergencyContactName,
          contactPhone: registration.emergencyContactPhone,
        ),
      ],
    );
  }
}

