import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/constants/auth_form_fields.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

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
      final email = (_formKey.currentState!.value[AuthFormFields.email] as String).trim();
      context.read<AuthCubit>().sendPasswordResetEmail(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: _onAuthStateChanged,
      child: Scaffold(
        backgroundColor: AppColors.darkBgPrimary,
        body: SafeArea(
          child: _sent
              ? _EmailSentContent(email: _sentEmail)
              : _ForgotPasswordForm(
                  formKey: _formKey,
                  onSend: () => _handleSend(context),
                ),
        ),
      ),
    );
  }
}

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 48),
            const _BrandHeader(),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => context.pop(),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.textOnDarkSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.auth_forgotPasswordTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.auth_forgotPasswordBody,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textOnDarkSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FormBuilder(
              key: formKey,
              child: Column(
                children: [
                  FormBuilderTextField(
                    name: AuthFormFields.email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: context.l10n.auth_emailHint,
                      prefixIcon: const Icon(
                        Icons.mail_outline,
                        color: AppColors.textOnDarkSecondary,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: AppColors.darkBgSecondary,
                      hintStyle: const TextStyle(
                        color: AppColors.tabInactive,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.darkBorderPrimary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.darkBorderPrimary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: 'El correo es requerido'),
                      FormBuilderValidators.email(
                          errorText: 'Correo inválido'),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: onSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.darkBgPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(context.l10n.auth_sendLink),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: () => context.goNamed(AppRoutes.login),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14),
                    children: [
                      TextSpan(
                        text: '${context.l10n.auth_rememberPassword} ',
                        style: const TextStyle(
                            color: AppColors.textOnDarkSecondary),
                      ),
                      TextSpan(
                        text: context.l10n.auth_signInLink2,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _EmailSentContent extends StatelessWidget {
  const _EmailSentContent({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),
          const _BrandHeader(),
          const Spacer(),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.primarySubtle,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mail_outline,
                color: AppColors.primary,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n.auth_emailSentTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.auth_emailSentBody,
            style: const TextStyle(
              fontSize: 14,
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
                color: AppColors.darkBgSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkBorderPrimary),
              ),
              child: Text(
                email,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const Spacer(),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => context.goNamed(AppRoutes.login),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.darkBgPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(context.l10n.auth_backToLogin),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              context.l10n.auth_resendEmail,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'RIDEGLORY',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Connect. Ride. Explore.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textOnDarkSecondary,
          ),
        ),
      ],
    );
  }
}
