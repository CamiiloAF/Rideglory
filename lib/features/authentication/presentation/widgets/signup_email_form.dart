import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/constants/auth_form_fields.dart';
import 'package:rideglory/features/authentication/constants/auth_strings.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';
import 'package:rideglory/shared/widgets/form/app_password_text_field.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';
import 'package:rideglory/shared/widgets/form/app_checkbox.dart';

/// Email/password signup form widget
class SignupEmailForm extends StatefulWidget {
  final GlobalKey<FormBuilderState> formKey;
  final VoidCallback onBack;

  const SignupEmailForm({
    super.key,
    required this.formKey,
    required this.onBack,
  });

  @override
  State<SignupEmailForm> createState() => _SignupEmailFormState();
}

class _SignupEmailFormState extends State<SignupEmailForm> {
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _handleEmailSignup(BuildContext context) {
    if (widget.formKey.currentState?.saveAndValidate() ?? false) {
      final formData = widget.formKey.currentState!.value;

      // Check if terms are accepted
      final acceptedTerms = formData[AuthFormFields.acceptTerms] as bool?;
      if (acceptedTerms != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AuthStrings.acceptTermsError),
            backgroundColor: context.errorColor,
          ),
        );
        return;
      }

      context.read<AuthCubit>().signUpWithEmail(
        email: (formData[AuthFormFields.email] as String).trim(),
        password: formData[AuthFormFields.password] as String,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: widget.formKey,
      child: Column(
        children: [
          AppTextField(
            name: AuthFormFields.email,
            labelText: AuthStrings.email,
            hintText: AuthStrings.enterEmail,
            prefixIcon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            focusNode: _emailFocusNode,
            onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: AuthStrings.emailRequired,
              ),
              FormBuilderValidators.email(errorText: AuthStrings.invalidEmail),
            ]),
          ),
          const SizedBox(height: 16),
          AppPasswordTextField(
            name: AuthFormFields.password,
            labelText: AuthStrings.password,
            hintText: AuthStrings.createPassword,
            textInputAction: TextInputAction.next,
            focusNode: _passwordFocusNode,
            onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: AuthStrings.passwordRequired,
              ),
              FormBuilderValidators.minLength(
                8,
                errorText: AuthStrings.passwordMinLength8,
              ),
              FormBuilderValidators.match(
                RegExp(r'[A-Z]'),
                errorText: AuthStrings.passwordNeedsUppercase,
              ),
              FormBuilderValidators.match(
                RegExp(r'[0-9]'),
                errorText: AuthStrings.passwordNeedsNumber,
              ),
            ]),
          ),
          const SizedBox(height: 16),
          AppPasswordTextField(
            name: AuthFormFields.confirmPassword,
            labelText: AuthStrings.confirmPassword,
            hintText: AuthStrings.confirmYourPassword,
            prefixIcon: Icons.lock_outline_rounded,
            textInputAction: TextInputAction.done,
            focusNode: _confirmPasswordFocusNode,
            onFieldSubmitted: (_) => _handleEmailSignup(context),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: AuthStrings.confirmPasswordRequired,
              ),
              (value) {
                final password = widget
                    .formKey
                    .currentState
                    ?.fields[AuthFormFields.password]
                    ?.value;
                if (value != password) {
                  return AuthStrings.passwordsDoNotMatch;
                }
                return null;
              },
            ]),
          ),
          const SizedBox(height: 24),

          // Terms and conditions checkbox
          AppCheckbox(
            name: AuthFormFields.acceptTerms,
            title: '',
            initialValue: false,
            customTitle: RichText(
              text: const TextSpan(
                text: AuthStrings.acceptTerms,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: AuthStrings.termsOfService,
                    style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: ' y ',
                    style: TextStyle(color: Color(0xFF374151)),
                  ),
                  TextSpan(
                    text: AuthStrings.privacyPolicy,
                    style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sign up button
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              return AppButton(
                onPressed: state.isLoading
                    ? null
                    : () => _handleEmailSignup(context),
                label: AuthStrings.createAccount,
              );
            },
          ),
          const SizedBox(height: 16),

          // Back button
          AppButton(
            onPressed: widget.onBack,
            label: AppStrings.back,
            variant: AppButtonVariant.outline,
          ),
        ],
      ),
    );
  }
}
