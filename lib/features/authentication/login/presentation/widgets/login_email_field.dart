import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/authentication/constants/auth_form_fields.dart';
import 'package:rideglory/features/authentication/constants/auth_strings.dart';
import 'package:rideglory/design_system/design_system.dart';

class LoginEmailField extends StatelessWidget {
  const LoginEmailField({super.key});

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      name: AuthFormFields.email,
      labelText: AuthStrings.emailLabel,
      hintText: AuthStrings.emailHint,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: AuthStrings.emailRequired),
        FormBuilderValidators.email(errorText: AuthStrings.invalidEmail),
      ]),
    );
  }
}
