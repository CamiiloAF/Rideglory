import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/features/events/constants/registration_strings.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/registration/detail/widgets/registration_detail_info_row.dart';
import 'package:rideglory/features/events/presentation/registration/detail/widgets/registration_detail_section.dart';

class RegistrationDetailPersonalSection extends StatelessWidget {
  const RegistrationDetailPersonalSection({
    super.key,
    required this.registration,
  });

  final EventRegistrationModel registration;

  static final _dateFormat = DateFormat("d 'de' MMMM, y", 'es');

  @override
  Widget build(BuildContext context) {
    return RegistrationDetailSection(
      title: RegistrationStrings.personalInfo,
      icon: Icons.person_outline,
      children: [
        RegistrationDetailInfoRow(
          RegistrationStrings.fullNameLabel,
          registration.fullName,
        ),
        RegistrationDetailInfoRow(
          RegistrationStrings.identificationIdLabel,
          registration.identificationNumber,
        ),
        RegistrationDetailInfoRow(
          RegistrationStrings.email,
          registration.email,
        ),
        RegistrationDetailInfoRow(
          RegistrationStrings.phone,
          registration.phone,
        ),
        RegistrationDetailInfoRow(
          RegistrationStrings.birthDateLabel,
          _dateFormat.format(registration.birthDate),
        ),
        RegistrationDetailInfoRow(
          RegistrationStrings.cityLabel,
          registration.residenceCity,
        ),
      ],
    );
  }
}

