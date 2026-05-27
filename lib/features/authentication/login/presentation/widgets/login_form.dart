import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/authentication/constants/auth_form_fields.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
    required this.formKey,
    required this.isLoading,
    required this.onLogin,
  });

  final GlobalKey<FormBuilderState> formKey;
  final bool isLoading;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            name: AuthFormFields.email,
            labelText: context.l10n.auth_email_label,
            hintText: context.l10n.auth_email_placeholder,
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
            textInputAction: TextInputAction.next,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: context.l10n.auth_emailRequired,
              ),
              FormBuilderValidators.email(
                errorText: context.l10n.auth_invalidEmail,
              ),
            ]),
          ),
          const SizedBox(height: 16),
          AppPasswordTextField(
            name: AuthFormFields.password,
            labelText: context.l10n.auth_password_label,
            hintText: context.l10n.auth_password_placeholder,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.none,
            onFieldSubmitted: (_) => onLogin(),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: context.l10n.auth_passwordRequired,
              ),
              FormBuilderValidators.minLength(
                6,
                errorText: context.l10n.auth_passwordMinLength,
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: AppTextButton(
              label: context.l10n.auth_forgot_password,
              onPressed: () => context.pushNamed(AppRoutes.forgotPassword),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: context.l10n.auth_sign_in,
            onPressed: onLogin,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}
