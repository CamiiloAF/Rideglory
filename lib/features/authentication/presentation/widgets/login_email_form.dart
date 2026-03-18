import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/constants/auth_form_fields.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class LoginEmailForm extends StatelessWidget {
  final GlobalKey<FormBuilderState> formKey;

  const LoginEmailForm({super.key, required this.formKey});

  void _handleEmailLogin(BuildContext context) {
    if (formKey.currentState?.saveAndValidate() ?? false) {
      final formData = formKey.currentState!.value;
      context.read<AuthCubit>().signInWithEmail(
        email: (formData[AuthFormFields.email] as String).trim(),
        password: formData[AuthFormFields.password] as String,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: formKey,
      child: Column(
        children: [
          AppTextField(
            name: AuthFormFields.email,
            labelText: context.l10n.auth_email,
            hintText: context.l10n.auth_enterEmail,
            prefixIcon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: context.l10n.auth_emailRequired,
              ),
              FormBuilderValidators.email(errorText: context.l10n.auth_invalidEmail),
            ]),
          ),
          SizedBox(height: 16),
          AppPasswordTextField(
            name: AuthFormFields.password,
            labelText: context.l10n.auth_password,
            hintText: context.l10n.auth_enterPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleEmailLogin(context),
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
          SizedBox(height: 24),

          // Sign in button
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              return AppButton(
                onPressed: state.isLoading
                    ? null
                    : () => _handleEmailLogin(context),
                label: context.l10n.auth_signIn,
              );
            },
          ),
        ],
      ),
    );
  }
}
