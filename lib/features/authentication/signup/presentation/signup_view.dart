import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/constants/auth_strings.dart';
import 'package:rideglory/features/authentication/presentation/widgets/signup_email_form.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _formKey = GlobalKey<FormBuilderState>();

  void _navigateToLogin() {
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colorScheme.onSurface),
          onPressed: _navigateToLogin,
        ),
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state.isAuthenticatedWithVehicles) {
            context.pushReplacementNamed(AppRoutes.maintenances);
          } else if (state.isAuthenticatedWithoutVehicles) {
            context.pushReplacementNamed(AppRoutes.vehicleOnboarding);
          } else if (state.hasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? AppStrings.errorOccurred),
                backgroundColor: context.colorScheme.error,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AuthStrings.registerTitle,
                style: context.textTheme.displaySmall?.copyWith(
                  color: context.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AuthStrings.registerSubtitle,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              SignupEmailForm(formKey: _formKey, onBack: _navigateToLogin),
              const SizedBox(height: 20),
              Center(
                child: RichText(
                  text: TextSpan(
                    text: '${AuthStrings.registerSignInQuestion} ',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: _navigateToLogin,
                          child: Text(
                            AuthStrings.registerSignInLink,
                            style: context.textTheme.labelMedium?.copyWith(
                              color: context.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
