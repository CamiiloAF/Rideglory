import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/constants/registration_form_fields.dart';
import 'package:rideglory/features/event_registration/presentation/wizard/registration_step_header.dart';
import 'package:rideglory/shared/widgets/form/form_focus_chain.dart';

class RegistrationPersonalStep extends StatelessWidget {
  const RegistrationPersonalStep({super.key, required this.focusChain});

  final FormFocusChain focusChain;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegistrationStepHeader(
          icon: Icons.person_outline,
          title: context.l10n.registration_stepPersonalTitle,
          subtitle: context.l10n.registration_stepPersonalSubtitle,
        ),
        AppSpacing.gapLg,
        AppTextField(
          name: RegistrationFormFields.fullName,
          labelText: context.l10n.registration_fullName,
          hintText: context.l10n.registration_fullNameHint,
          isRequired: true,
          textCapitalization: TextCapitalization.words,
          focusNode: focusChain.nodeFor(RegistrationFormFields.fullName),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) =>
              focusChain.requestNextAfter(RegistrationFormFields.fullName),
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(
              errorText: context.l10n.registration_fullNameRequired,
            ),
            FormBuilderValidators.minLength(
              2,
              errorText: context.l10n.registration_minCharacters,
            ),
          ]),
        ),
        AppSpacing.gapMd,
        AppTextField(
          name: RegistrationFormFields.identificationNumber,
          labelText: context.l10n.registration_identificationNumber,
          hintText: context.l10n.registration_identificationHint,
          isRequired: true,
          keyboardType: TextInputType.number,
          maxLength: 10,
          focusNode: focusChain.nodeFor(
            RegistrationFormFields.identificationNumber,
          ),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => focusChain.requestNextAfter(
            RegistrationFormFields.identificationNumber,
          ),
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(
              errorText: context.l10n.registration_idRequired,
            ),
            FormBuilderValidators.numeric(
              errorText: context.l10n.registration_idInvalidLength,
            ),
            FormBuilderValidators.minLength(
              6,
              errorText: context.l10n.registration_idInvalidLength,
            ),
            FormBuilderValidators.maxLength(
              10,
              errorText: context.l10n.registration_idInvalidLength,
            ),
          ]),
        ),
        AppSpacing.gapMd,
        AppDatePicker(
          fieldName: RegistrationFormFields.birthDate,
          labelText: context.l10n.registration_birthDate,
          isRequired: true,
          requiredErrorText: context.l10n.registration_birthDateRequired,
          lastDate: DateTime(
            DateTime.now().year - 18,
            DateTime.now().month,
            DateTime.now().day,
          ),
          hintText: context.l10n.registration_birthDateHint,
          focusNode: focusChain.nodeFor(RegistrationFormFields.birthDate),
        ),
        AppSpacing.gapMd,
        AppTextField(
          name: RegistrationFormFields.phone,
          labelText: context.l10n.registration_phone,
          hintText: context.l10n.registration_phoneHint,
          isRequired: true,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          focusNode: focusChain.nodeFor(RegistrationFormFields.phone),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) =>
              focusChain.requestNextAfter(RegistrationFormFields.phone),
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(
              errorText: context.l10n.registration_phoneRequired,
            ),
            FormBuilderValidators.numeric(
              errorText: context.l10n.registration_phoneInvalidLength,
            ),
            FormBuilderValidators.minLength(
              10,
              errorText: context.l10n.registration_phoneInvalidLength,
            ),
            FormBuilderValidators.maxLength(
              10,
              errorText: context.l10n.registration_phoneInvalidLength,
            ),
          ]),
        ),
        AppSpacing.gapMd,
        AppTextField(
          name: RegistrationFormFields.email,
          labelText: context.l10n.registration_email,
          hintText: context.l10n.registration_emailHint,
          isRequired: true,
          keyboardType: TextInputType.emailAddress,
          focusNode: focusChain.nodeFor(RegistrationFormFields.email),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) =>
              focusChain.requestNextAfter(RegistrationFormFields.email),
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(
              errorText: context.l10n.registration_emailRequired,
            ),
            FormBuilderValidators.email(
              errorText: context.l10n.registration_emailInvalid,
            ),
          ]),
        ),
        AppSpacing.gapMd,
        AppCityAutocomplete(
          name: RegistrationFormFields.residenceCity,
          labelText: context.l10n.registration_residenceCity,
          hintText: context.l10n.registration_residenceCityHint,
          isRequired: true,
          focusNode: focusChain.nodeFor(RegistrationFormFields.residenceCity),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) =>
              focusChain.requestNextAfter(RegistrationFormFields.residenceCity),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return context.l10n.registration_residenceCityRequired;
            }
            return null;
          },
        ),
      ],
    );
  }
}
