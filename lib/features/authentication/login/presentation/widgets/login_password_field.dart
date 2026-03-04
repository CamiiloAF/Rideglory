import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/authentication/constants/auth_form_fields.dart';
import 'package:rideglory/features/authentication/constants/auth_strings.dart';
import 'package:rideglory/shared/widgets/form/app_password_text_field.dart';

class LoginPasswordField extends StatelessWidget {
  final VoidCallback onSubmitted;

  const LoginPasswordField({super.key, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return AppPasswordTextField(
      name: AuthFormFields.password,
      labelText: AuthStrings.passwordLabel,
      hintText: AuthStrings.passwordHint,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => onSubmitted(),
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: AuthStrings.passwordRequired),
        FormBuilderValidators.minLength(
          6,
          errorText: AuthStrings.passwordMinLength,
        ),
      ]),
    );
  }
}
