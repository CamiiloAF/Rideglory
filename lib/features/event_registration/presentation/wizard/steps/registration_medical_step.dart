import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/constants/registration_form_fields.dart';
import 'package:rideglory/features/event_registration/presentation/wizard/registration_blood_type_selector.dart';
import 'package:rideglory/features/event_registration/presentation/wizard/registration_step_header.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_form_section_header.dart';
import 'package:rideglory/shared/widgets/form/app_switch_tile.dart';
import 'package:rideglory/shared/widgets/form/form_focus_chain.dart';

class RegistrationMedicalStep extends StatelessWidget {
  const RegistrationMedicalStep({super.key, required this.focusChain});

  final FormFocusChain focusChain;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegistrationStepHeader(
          icon: Icons.favorite_outline,
          title: context.l10n.registration_stepMedicalTitle,
          subtitle: context.l10n.registration_stepMedicalSubtitle,
        ),
        AppSpacing.gapLg,
        AppTextField(
          name: RegistrationFormFields.eps,
          labelText: context.l10n.registration_eps,
          hintText: context.l10n.registration_epsHint,
          isRequired: true,
          textCapitalization: TextCapitalization.words,
          focusNode: focusChain.nodeFor(RegistrationFormFields.eps),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) =>
              focusChain.requestNextAfter(RegistrationFormFields.eps),
          validator: FormBuilderValidators.required(
            errorText: context.l10n.registration_epsRequired,
          ),
        ),
        AppSpacing.gapMd,
        AppTextField(
          name: RegistrationFormFields.medicalInsurance,
          labelText: context.l10n.registration_medicalInsurance,
          hintText: context.l10n.registration_medicalInsuranceHint,
          textCapitalization: TextCapitalization.words,
          focusNode: focusChain.nodeFor(
            RegistrationFormFields.medicalInsurance,
          ),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => focusChain.requestNextAfter(
            RegistrationFormFields.medicalInsurance,
          ),
        ),
        AppSpacing.gapLg,
        const RegistrationBloodTypeSelector(),
        AppSpacing.gapLg,
        ProfileFormSectionHeader(
          label: context.l10n.registration_privacySectionTitle,
        ),
        AppSpacing.gapSm,
        AppSwitchTile(
          name: RegistrationFormFields.shareMedicalInfo,
          title: context.l10n.registration_shareMedicalInfoTitle,
          subtitle: context.l10n.registration_shareMedicalInfoSubtitle,
          initialValue: false,
        ),
        AppSwitchTile(
          name: RegistrationFormFields.allowOrganizerContact,
          title: context.l10n.registration_allowContactTitle,
          subtitle: context.l10n.registration_allowContactSubtitle,
          initialValue: false,
        ),
      ],
    );
  }
}
