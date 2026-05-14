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

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _sent = false;
  String _sentEmail = '';

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state.isPasswordResetEmailSent && !_sent) {
      final email = _formKey.currentState?.fields[AuthFormFields.email]?.value
              as String? ??
          '';
      setState(() {
        _sent = true;
        _sentEmail = email.trim();
      });
    } else if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? ''),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleSend(BuildContext context) {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final email =
          (_formKey.currentState!.value[AuthFormFields.email] as String).trim();
      context.read<AuthCubit>().sendPasswordResetEmail(email);
    }
  }

  void _handleResend(BuildContext context) {
    if (_sentEmail.isNotEmpty) {
      context.read<AuthCubit>().sendPasswordResetEmail(_sentEmail);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      body: BlocListener<AuthCubit, AuthState>(
        listener: _onAuthStateChanged,
        child: SafeArea(
          child: _sent
              ? _EmailSentContent(
                  email: _sentEmail,
                  onResend: () => _handleResend(context),
                )
              : _ForgotPasswordForm(
                  formKey: _formKey,
                  onSend: () => _handleSend(context),
                ),
        ),
      ),
    );
  }
}

// ─── Forgot Password Form ───────────────────────────────────────────────────

class _ForgotPasswordForm extends StatelessWidget {
  const _ForgotPasswordForm({
    required this.formKey,
    required this.onSend,
  });

  final GlobalKey<FormBuilderState> formKey;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          _BackButton(),
          const SizedBox(height: 32),
          const _ForgotPasswordHeading(),
          const SizedBox(height: 32),
          _ForgotPasswordEmailField(formKey: formKey),
          const SizedBox(height: 24),
          _SendLinkButton(onSend: onSend),
          const SizedBox(height: 24),
          _BackToLoginLink(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
    );
  }
}

class _ForgotPasswordHeading extends StatelessWidget {
  const _ForgotPasswordHeading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.auth_recovery_heading,
          style: context.textTheme.displaySmall?.copyWith(
            color: AppColors.textOnDarkPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.auth_recovery_subtitle,
          style: context.textTheme.bodyMedium?.copyWith(
            color: AppColors.textOnDarkSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ForgotPasswordEmailField extends StatelessWidget {
  const _ForgotPasswordEmailField({required this.formKey});

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

class _SendLinkButton extends StatelessWidget {
  const _SendLinkButton({required this.onSend});

  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return AppButton(
          label: context.l10n.auth_recovery_send,
          onPressed: onSend,
          isLoading: state.isLoading,
        );
      },
    );
  }
}

class _BackToLoginLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => context.goNamed(AppRoutes.login),
        child: Text(
          context.l10n.auth_recovery_back,
          style: context.textTheme.bodySmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Email Sent Content ─────────────────────────────────────────────────────

class _EmailSentContent extends StatelessWidget {
  const _EmailSentContent({
    required this.email,
    required this.onResend,
  });

  final String email;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          _EmailSentIcon(),
          const SizedBox(height: 24),
          Text(
            context.l10n.auth_recovery_sent_title,
            style: context.textTheme.displaySmall?.copyWith(
              color: AppColors.textOnDarkPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.auth_recovery_sent_body(email),
            style: context.textTheme.bodyMedium?.copyWith(
              color: AppColors.textOnDarkSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkBorderPrimary),
              ),
              child: Text(
                email,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textOnDarkPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const Spacer(),
          AppButton(
            label: context.l10n.auth_recovery_back_home,
            onPressed: () => context.goNamed(AppRoutes.login),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: onResend,
              child: Text(
                context.l10n.auth_recovery_resend,
                style: context.textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _EmailSentIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          color: AppColors.primarySubtle,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.mail_outline_rounded,
          color: AppColors.primary,
          size: 40,
        ),
      ),
    );
  }
}
