import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/constants/auth_form_fields.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/login_divider.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/login_email_field.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/login_heading.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/login_password_field.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/login_register_link.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/login_sign_in_button.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/login_social_row.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormBuilderState>();

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state.isAuthenticatedWithVehicles || state.isAuthenticatedWithoutVehicles) {
      context.pushReplacementNamed(AppRoutes.home);
    } else if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? ''),
          backgroundColor: context.colorScheme.error,
        ),
      );
    }
  }

  void _handleLogin(BuildContext context) {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
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
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: AppColors.darkBackground,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            context.l10n.appName.toUpperCase(),
            style: context.textTheme.titleSmall?.copyWith(
              color: context.colorScheme.onSurface,
              letterSpacing: 2.0,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocListener<AuthCubit, AuthState>(
          listener: _onAuthStateChanged,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 160),
                  const LoginHeading(),
                  SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FormBuilder(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const LoginEmailField(),
                          SizedBox(height: 18),
                          LoginPasswordField(
                            onSubmitted: () => _handleLogin(context),
                          ),
                          SizedBox(height: 20),
                          LoginSignInButton(
                            onPressed: () => _handleLogin(context),
                          ),
                          SizedBox(height: 24),
                          const LoginDivider(),
                          SizedBox(height: 20),
                          const LoginSocialRow(),
                          SizedBox(height: 28),
                          LoginRegisterLink(
                            onTap: () => context.push(AppRoutes.signup),
                          ),
                          SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
