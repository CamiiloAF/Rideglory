import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/constants/auth_form_fields.dart';
import 'package:rideglory/features/authentication/signup/presentation/widgets/signup_form.dart';
import 'package:rideglory/features/authentication/signup/presentation/widgets/signup_heading.dart';
import 'package:rideglory/features/authentication/signup/presentation/widgets/signup_sign_in_row.dart';
import 'package:rideglory/features/authentication/signup/presentation/widgets/signup_top_bar.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _completedSuccessfully = false;

  AnalyticsService get _analytics => getIt<AnalyticsService>();

  @override
  void initState() {
    super.initState();
    _analytics.logEvent(AnalyticsEvents.authFlowStarted, {
      AnalyticsParams.authMethod: AnalyticsParams.authMethodSignup,
    }).ignore();
  }

  @override
  void dispose() {
    if (!_completedSuccessfully) {
      _analytics.logEvent(AnalyticsEvents.authAbandoned, {
        AnalyticsParams.authMethod: AnalyticsParams.authMethodSignup,
      }).ignore();
    }
    super.dispose();
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state.isAuthenticated) {
      _completedSuccessfully = true;
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
      _analytics.logEvent(AnalyticsEvents.authMethodSelected, {
        AnalyticsParams.authMethod: AnalyticsParams.authMethodEmail,
      }).ignore();
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
                const SignupTopBar(),
                const SizedBox(height: 32),
                const SignupHeading(),
                const SizedBox(height: 32),
                SignupForm(
                  formKey: _formKey,
                  onSignup: () => _handleSignup(context),
                ),
                const SizedBox(height: 24),
                const SignupSignInRow(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
