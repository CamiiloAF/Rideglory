import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/constants/auth_form_fields.dart';
import 'package:rideglory/features/authentication/signup/presentation/widgets/signup_terms_text.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

/// Email/password signup form — colors via theme, strings via AuthStrings.
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

      final acceptedTerms = formData[AuthFormFields.acceptTerms] as bool?;
      if (acceptedTerms != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.auth_acceptTermsError),
            backgroundColor: Theme.of(context).colorScheme.error,
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
            hintText: context.l10n.auth_emailHint,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            focusNode: _emailFocusNode,
            onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: context.l10n.auth_emailRequired,
              ),
              FormBuilderValidators.email(errorText: context.l10n.auth_invalidEmail),
            ]),
          ),
          AppSpacing.gapLg,
          AppPasswordTextField(
            name: AuthFormFields.password,
            hintText: context.l10n.auth_passwordMinStitch,
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
          AppSpacing.gapLg,
          AppPasswordTextField(
            name: AuthFormFields.confirmPassword,
            hintText: context.l10n.auth_confirmYourPassword,
            textInputAction: TextInputAction.done,
            focusNode: _confirmPasswordFocusNode,
            onFieldSubmitted: (_) => _handleEmailSignup(context),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: context.l10n.auth_confirmPasswordRequired,
              ),
              (value) {
                final password = widget
                    .formKey
                    .currentState
                    ?.fields[AuthFormFields.password]
                    ?.value;
                if (value != password) return context.l10n.auth_passwordsDoNotMatch;
                return null;
              },
            ]),
          ),
          AppSpacing.gapXxl,
          const AppCheckbox(
            name: AuthFormFields.acceptTerms,
            title: '',
            initialValue: false,
            customTitle: SignupTermsText(),
          ),
          AppSpacing.gapXxl,
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              return AppButton(
                onPressed: state.isLoading
                    ? null
                    : () => _handleEmailSignup(context),
                label: context.l10n.auth_createAccountButton,
              );
            },
          ),
        ],
      ),
    );
  }
}
