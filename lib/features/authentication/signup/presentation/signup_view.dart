import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/presentation/widgets/signup_header.dart';
import 'package:rideglory/features/authentication/presentation/widgets/signup_social_buttons.dart';
import 'package:rideglory/features/authentication/presentation/widgets/signup_email_form.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/features/authentication/constants/auth_strings.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

/// Modern sign-up view for creating a new account
class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isEmailMode = false;

  void _toggleEmailMode() {
    setState(() => _isEmailMode = true);
  }

  void _handleBackToSocial() {
    setState(() => _isEmailMode = false);
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state.isAuthenticatedWithVehicles) {
              context.pushReplacementNamed(AppRoutes.maintenances);
            } else if (state.isAuthenticatedWithoutVehicles) {
              context.pushReplacementNamed(AppRoutes.vehicleOnboarding);
            } else if (state.hasError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? AppStrings.errorOccurred),
                  backgroundColor: context.errorColor,
                ),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                SignupHeader(
                  isEmailMode: _isEmailMode,
                  emailModeTitle: AuthStrings.createAccount,
                  emailModeSubtitle: AuthStrings.signupSubtitleEmail,
                  socialModeTitle: AuthStrings.joinToday,
                  socialModeSubtitle: AuthStrings.signupSubtitleSocial,
                ),
                const SizedBox(height: 48),

                // Content based on mode
                if (!_isEmailMode)
                  SignupSocialButtons(onEmailModeToggle: _toggleEmailMode)
                else
                  SignupEmailForm(
                    formKey: _formKey,
                    onBack: _handleBackToSocial,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
