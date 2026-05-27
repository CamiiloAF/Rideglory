import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/constants/auth_form_fields.dart';
import 'package:rideglory/features/authentication/signup/presentation/widgets/signup_terms_checkbox.dart';

class SignupForm extends StatefulWidget {
  const SignupForm({
    super.key,
    required this.formKey,
    required this.onSignup,
  });

  final GlobalKey<FormBuilderState> formKey;
  final VoidCallback onSignup;

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final _fullNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  bool _termsAccepted = false;

  @override
  void dispose() {
    _fullNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.auth_acceptTermsError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    widget.onSignup();
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            name: AuthFormFields.fullName,
            labelText: context.l10n.auth_full_name_label,
            hintText: context.l10n.auth_nameHint,
            textInputAction: TextInputAction.next,
            focusNode: _fullNameFocusNode,
            onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: context.l10n.auth_nameRequired,
              ),
              FormBuilderValidators.minLength(
                3,
                errorText: context.l10n.event_minCharacters,
              ),
            ]),
          ),
          const SizedBox(height: 16),
          AppTextField(
            name: AuthFormFields.email,
            labelText: context.l10n.auth_email_label,
            hintText: context.l10n.auth_email_placeholder,
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
            textInputAction: TextInputAction.next,
            focusNode: _emailFocusNode,
            onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
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
            textInputAction: TextInputAction.next,
            focusNode: _passwordFocusNode,
            onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: context.l10n.auth_passwordRequired,
              ),
              FormBuilderValidators.minLength(
                8,
                errorText: context.l10n.auth_passwordMinLength8,
              ),
              FormBuilderValidators.match(
                RegExp(r'[A-Z]'),
                errorText: context.l10n.auth_passwordNeedsUppercase,
              ),
              FormBuilderValidators.match(
                RegExp(r'[0-9]'),
                errorText: context.l10n.auth_passwordNeedsNumber,
              ),
            ]),
          ),
          const SizedBox(height: 16),
          AppPasswordTextField(
            name: AuthFormFields.confirmPassword,
            labelText: context.l10n.auth_confirm_password_label,
            hintText: context.l10n.auth_confirmYourPassword,
            textInputAction: TextInputAction.done,
            focusNode: _confirmPasswordFocusNode,
            onFieldSubmitted: (_) => _submit(context),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: context.l10n.auth_confirmPasswordRequired,
              ),
              (value) {
                final password = widget.formKey.currentState
                    ?.fields[AuthFormFields.password]?.value;
                if (value != password) {
                  return context.l10n.auth_passwordsDoNotMatch;
                }
                return null;
              },
            ]),
          ),
          const SizedBox(height: 20),
          SignupTermsCheckbox(
            accepted: _termsAccepted,
            onChanged: (value) => setState(() => _termsAccepted = value),
          ),
          const SizedBox(height: 24),
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              return AppButton(
                label: context.l10n.auth_create_account_btn,
                onPressed: () => _submit(context),
                isLoading: state.isLoading,
              );
            },
          ),
        ],
      ),
    );
  }
}
