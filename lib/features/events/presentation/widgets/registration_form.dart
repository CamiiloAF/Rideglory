import 'package:flutter/material.dart';

import '../../../../design_system/components/app_switch_tile.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../profile/domain/profile.dart';
import '../../domain/event_vehicle_option.dart';
import 'registration_data_card.dart';
import 'registration_risk_row.dart';
import 'registration_section_label.dart';
import 'registration_vehicle_field.dart';

/// Formulario de EV4: datos precargados + moto + permisos + riesgos.
class RegistrationForm extends StatelessWidget {
  const RegistrationForm({
    required this.profile,
    required this.vehicles,
    required this.selectedVehicleId,
    required this.onVehicleSelected,
    required this.shareMedicalInfo,
    required this.onShareMedicalInfoChanged,
    required this.allowOrganizerContact,
    required this.onAllowOrganizerContactChanged,
    required this.acceptsRisk,
    required this.onAcceptsRiskChanged,
    super.key,
  });

  final Profile profile;
  final List<EventVehicleOption> vehicles;
  final String? selectedVehicleId;
  final ValueChanged<String?> onVehicleSelected;
  final bool shareMedicalInfo;
  final ValueChanged<bool> onShareMedicalInfoChanged;
  final bool allowOrganizerContact;
  final ValueChanged<bool> onAllowOrganizerContactChanged;
  final bool acceptsRisk;
  final ValueChanged<bool> onAcceptsRiskChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RegistrationSectionLabel(
            context.l10n.events_register_your_data_label,
          ),
          const SizedBox(height: 10),
          RegistrationDataCard(profile: profile),
          const SizedBox(height: 8),
          Text(
            context.l10n.events_register_edit_profile_note,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          RegistrationVehicleField(
            vehicles: vehicles,
            selectedVehicleId: selectedVehicleId,
            onSelected: onVehicleSelected,
          ),
          if (vehicles.isNotEmpty) const SizedBox(height: 16),
          RegistrationSectionLabel(
            context.l10n.events_register_permissions_label,
          ),
          const SizedBox(height: 10),
          AppSwitchTile(
            label: context.l10n.events_register_share_medical_label,
            subtitle: context.l10n.events_register_share_medical_subtitle,
            value: shareMedicalInfo,
            onChanged: onShareMedicalInfoChanged,
          ),
          const SizedBox(height: 14),
          AppSwitchTile(
            label: context.l10n.events_register_allow_contact_label,
            subtitle: context.l10n.events_register_allow_contact_subtitle,
            value: allowOrganizerContact,
            onChanged: onAllowOrganizerContactChanged,
          ),
          const SizedBox(height: 16),
          RegistrationSectionLabel(context.l10n.events_register_risk_label),
          const SizedBox(height: 10),
          RegistrationRiskRow(
            value: acceptsRisk,
            onChanged: onAcceptsRiskChanged,
          ),
        ],
      ),
    );
  }
}
