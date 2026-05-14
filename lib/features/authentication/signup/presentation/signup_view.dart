import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/constants/auth_form_fields.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _formKey = GlobalKey<FormBuilderState>();

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state.isAuthenticated) {
      context.pushReplacementNamed(AppRoutes.home);
    } else if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? context.l10n.errorOccurred),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleSignup(BuildContext context) {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final data = _formKey.currentState!.value;
      context.read<AuthCubit>().signUpWithEmail(
        fullName: (data[AuthFormFields.fullName] as String).trim(),
        email: (data[AuthFormFields.email] as String).trim(),
        password: data[AuthFormFields.password] as String,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      body: BlocListener<AuthCubit, AuthState>(
        listener: _onAuthStateChanged,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                _SignupTopBar(),
                const SizedBox(height: 32),
                _SignupHeading(),
                const SizedBox(height: 32),
                _SignupForm(
                  formKey: _formKey,
                  onSignup: () => _handleSignup(context),
                ),
                const SizedBox(height: 24),
                _SignupSignInRow(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignupTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (context.canPop()) context.pop();
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorderPrimary),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.textOnDarkPrimary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class _SignupHeading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.auth_join_community,
          style: context.textTheme.displaySmall?.copyWith(
            color: AppColors.textOnDarkPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.auth_create_account_title,
          style: context.textTheme.bodyMedium?.copyWith(
            color: AppColors.textOnDarkSecondary,
          ),
        ),
      ],
    );
  }
}

class _SignupForm extends StatefulWidget {
  const _SignupForm({
    required this.formKey,
    required this.onSignup,
  });

  final GlobalKey<FormBuilderState> formKey;
  final VoidCallback onSignup;

  @override
  State<_SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<_SignupForm> {
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
          _TermsCheckbox(
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

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.accepted,
    required this.onChanged,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!accepted),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: accepted,
              onChanged: (value) => onChanged(value ?? false),
              activeColor: AppColors.primary,
              side: const BorderSide(color: AppColors.darkBorderPrimary, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.auth_terms_text,
              style: context.textTheme.bodySmall?.copyWith(
                color: AppColors.textOnDarkSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignupSignInRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.l10n.auth_already_have_account,
          style: context.textTheme.bodySmall?.copyWith(
            color: AppColors.textOnDarkSecondary,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () {
            if (context.canPop()) context.pop();
          },
          child: Text(
            context.l10n.auth_sign_in_link,
            style: context.textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
