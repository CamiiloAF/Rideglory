import 'package:flutter/widgets.dart';

import '../../../../design_system/components/app_outlined_card.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../profile/domain/profile.dart';
import '../registration_labels.dart';
import 'labeled_value_row.dart';

/// Snapshot de los datos que se enviarán con la inscripción (EV4): lo que
/// ya hay en el perfil, de solo lectura -- se corrige desde Perfil, no
/// aquí.
class RegistrationDataCard extends StatelessWidget {
  const RegistrationDataCard({required this.profile, super.key});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final notProvided = context.l10n.events_register_not_provided;
    return AppOutlinedCard(
      children: [
        LabeledValueRow(
          label: context.l10n.events_register_name_field,
          value: profile.fullName?.trim().isNotEmpty ?? false
              ? profile.fullName!
              : notProvided,
        ),
        LabeledValueRow(
          label: context.l10n.events_register_phone_field,
          value: profile.phone?.trim().isNotEmpty ?? false
              ? profile.phone!
              : notProvided,
        ),
        LabeledValueRow(
          label: context.l10n.events_register_blood_type_field,
          value: profile.bloodType == null
              ? notProvided
              : bloodTypeShortLabel(profile.bloodType!),
        ),
        LabeledValueRow(
          label: context.l10n.events_register_eps_field,
          value: profile.eps?.trim().isNotEmpty ?? false
              ? profile.eps!
              : notProvided,
        ),
        LabeledValueRow(
          label: context.l10n.events_register_emergency_contact_field,
          value: profile.hasEmergencyContact
              ? '${profile.emergencyContactName} · ${profile.emergencyContactPhone}'
              : notProvided,
        ),
      ],
    );
  }
}
