import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/authentication/constants/auth_form_fields.dart';

class ForgotPasswordEmailField extends StatelessWidget {
  const ForgotPasswordEmailField({super.key, required this.formKey});

  final GlobalKey<FormBuilderState> formKey;

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: formKey,
      child: AppTextField(
        name: AuthFormFields.email,
        labelText: context.l10n.auth_email_label,
        hintText: context.l10n.auth_email_placeholder,
        keyboardType: TextInputType.emailAddress,
        textCapitalization: TextCapitalization.none,
        textInputAction: TextInputAction.done,
        validator: FormBuilderValidators.compose([
          FormBuilderValidators.required(
            errorText: context.l10n.auth_emailRequired,
          ),
          FormBuilderValidators.email(
            errorText: context.l10n.auth_invalidEmail,
          ),
        ]),
      ),
    );
  }
}
