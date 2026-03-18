import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/authentication/constants/auth_form_fields.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class LoginPasswordField extends StatelessWidget {
  final VoidCallback onSubmitted;

  const LoginPasswordField({super.key, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return AppPasswordTextField(
      name: AuthFormFields.password,
      labelText: context.l10n.auth_passwordLabel,
      hintText: context.l10n.auth_passwordHint,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => onSubmitted(),
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: context.l10n.auth_passwordRequired),
        FormBuilderValidators.minLength(
          6,
          errorText: context.l10n.auth_passwordMinLength,
        ),
      ]),
    );
  }
}
