import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/constants/auth_form_fields.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _emailLoading = false;

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (!state.isLoading) {
      setState(() => _emailLoading = false);
    }
    if (state.isAuthenticated) {
      context.pushReplacementNamed(AppRoutes.home);
    } else if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? ''),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleLogin(BuildContext context) {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _emailLoading = true);
      final data = _formKey.currentState!.value;
      context.read<AuthCubit>().signInWithEmail(
        email: (data[AuthFormFields.email] as String).trim(),
        password: data[AuthFormFields.password] as String,
      );
    }
  }

  void _showExitDialog(BuildContext context) {
    ConfirmationDialog.show(
      context: context,
      title: context.l10n.auth_exitLoginTitle,
      content: context.l10n.auth_exitLoginMessage,
      onConfirm: () => SystemNavigator.pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBgPrimary,
        body: BlocListener<AuthCubit, AuthState>(
          listener: _onAuthStateChanged,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  const _LoginBrandHeader(),
                  const SizedBox(height: 40),
                  _LoginHeading(),
                  const SizedBox(height: 32),
                  _LoginForm(
                    formKey: _formKey,
                    isLoading: _emailLoading,
                    onLogin: () => _handleLogin(context),
                  ),
                  const SizedBox(height: 24),
                  const _LoginDivider(),
                  const SizedBox(height: 24),
                  const _LoginSocialSection(),
                  const SizedBox(height: 32),
                  _LoginRegisterRow(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginBrandHeader extends StatelessWidget {
  const _LoginBrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'RIDEGLORY',
          style: context.textTheme.displayMedium?.copyWith(
            color: AppColors.primary,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Connect. Ride. Explore.',
          style: context.textTheme.bodyMedium?.copyWith(
            color: AppColors.textOnDarkSecondary,
          ),
        ),
      ],
    );
  }
}

class _LoginHeading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.auth_welcome_title,
          style: context.textTheme.displaySmall?.copyWith(
            color: AppColors.textOnDarkPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.auth_welcome_subtitle,
          style: context.textTheme.bodyMedium?.copyWith(
            color: AppColors.textOnDarkSecondary,
          ),
        ),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
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

class _LoginDivider extends StatelessWidget {
  const _LoginDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(height: 1, color: AppColors.darkBorderPrimary),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            context.l10n.auth_orContinueWithStitch,
            style: context.textTheme.labelSmall?.copyWith(
              color: AppColors.textOnDarkSecondary,
            ),
          ),
        ),
        const Expanded(
          child: Divider(height: 1, color: AppColors.darkBorderPrimary),
        ),
      ],
    );
  }
}

enum _AuthProvider { google, apple }

class _LoginSocialSection extends StatefulWidget {
  const _LoginSocialSection();

  @override
  State<_LoginSocialSection> createState() => _LoginSocialSectionState();
}

class _LoginSocialSectionState extends State<_LoginSocialSection> {
  _AuthProvider? _loadingProvider;

  void _onPressed(_AuthProvider provider, VoidCallback action) {
    setState(() => _loadingProvider = provider);
    action();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (!state.isLoading) {
          setState(() => _loadingProvider = null);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SocialButton(
            label: context.l10n.auth_continue_with_google,
            icon: Icons.g_mobiledata_rounded,
            backgroundColor: Colors.white,
            textColor: Colors.black,
            isLoading: _loadingProvider == _AuthProvider.google,
            isDisabled: _loadingProvider != null,
            onPressed: () => _onPressed(
              _AuthProvider.google,
              () => context.read<AuthCubit>().signInWithGoogle(),
            ),
          ),
          const SizedBox(height: 12),
          _SocialButton(
            label: context.l10n.auth_appleLabel,
            icon: Icons.apple,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            isLoading: _loadingProvider == _AuthProvider.apple,
            isDisabled: _loadingProvider != null,
            onPressed: () => _onPressed(
              _AuthProvider.apple,
              () => context.read<AuthCubit>().signInWithApple(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.isLoading,
    required this.isDisabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textColor,
                    ),
                  )
                else
                  Icon(icon, color: textColor, size: 22),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginRegisterRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.l10n.auth_no_account,
          style: context.textTheme.bodySmall?.copyWith(
            color: AppColors.textOnDarkSecondary,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => context.pushNamed(AppRoutes.signup),
          child: Text(
            context.l10n.auth_register_link,
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
