import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/constants/registration_form_fields.dart';
import 'package:rideglory/features/event_registration/presentation/wizard/registration_step_header.dart';
import 'package:rideglory/shared/widgets/form/form_focus_chain.dart';

class RegistrationEmergencyStep extends StatelessWidget {
  const RegistrationEmergencyStep({super.key, required this.focusChain});

  final FormFocusChain focusChain;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegistrationStepHeader(
          icon: Icons.phone_in_talk_outlined,
          title: context.l10n.registration_stepEmergencyTitle,
          subtitle: context.l10n.registration_stepEmergencySubtitle,
        ),
        AppSpacing.gapLg,
        AppTextField(
          name: RegistrationFormFields.emergencyContactName,
          labelText: context.l10n.registration_emergencyContactName,
          hintText: context.l10n.registration_emergencyContactNameHint,
          isRequired: true,
          textCapitalization: TextCapitalization.words,
          focusNode: focusChain.nodeFor(
            RegistrationFormFields.emergencyContactName,
          ),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => focusChain.requestNextAfter(
            RegistrationFormFields.emergencyContactName,
          ),
          validator: FormBuilderValidators.required(
            errorText: context.l10n.registration_emergencyContactNameRequired,
          ),
        ),
        AppSpacing.gapMd,
        AppTextField(
          name: RegistrationFormFields.emergencyContactPhone,
          labelText: context.l10n.registration_emergencyContactPhone,
          hintText: context.l10n.registration_emergencyContactPhoneHint,
          isRequired: true,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          focusNode: focusChain.nodeFor(
            RegistrationFormFields.emergencyContactPhone,
          ),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => focusChain.requestNextAfter(
            RegistrationFormFields.emergencyContactPhone,
          ),
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(
              errorText:
                  context.l10n.registration_emergencyContactPhoneRequired,
            ),
            FormBuilderValidators.numeric(
              errorText:
                  context.l10n.registration_emergencyContactPhoneInvalidLength,
            ),
            FormBuilderValidators.minLength(
              10,
              errorText:
                  context.l10n.registration_emergencyContactPhoneInvalidLength,
            ),
            FormBuilderValidators.maxLength(
              10,
              errorText:
                  context.l10n.registration_emergencyContactPhoneInvalidLength,
            ),
          ]),
        ),
      ],
    );
  }
}
