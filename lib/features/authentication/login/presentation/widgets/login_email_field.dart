import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/authentication/constants/auth_form_fields.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class LoginEmailField extends StatelessWidget {
  const LoginEmailField({super.key});

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      name: AuthFormFields.email,
      labelText: context.l10n.auth_emailLabel,
      hintText: context.l10n.auth_emailHint,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: context.l10n.auth_emailRequired),
        FormBuilderValidators.email(errorText: context.l10n.auth_invalidEmail),
      ]),
    );
  }
}
