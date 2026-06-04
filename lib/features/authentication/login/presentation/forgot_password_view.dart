import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/constants/auth_form_fields.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/forgot_password_email_sent_content.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/forgot_password_form.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _sent = false;
  String _sentEmail = '';
  bool _completedSuccessfully = false;

  AnalyticsService get _analytics => getIt<AnalyticsService>();

  @override
  void initState() {
    super.initState();
    _analytics
        .logEvent(AnalyticsEvents.authFlowStarted, {
          AnalyticsParams.authMethod: AnalyticsParams.authMethodForgotPassword,
        })
        .ignore();
  }

  @override
  void dispose() {
    if (!_completedSuccessfully) {
      _analytics
          .logEvent(AnalyticsEvents.authAbandoned, {
            AnalyticsParams.authMethod: AnalyticsParams.authMethodForgotPassword,
          })
          .ignore();
    }
    super.dispose();
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state.isPasswordResetEmailSent && !_sent) {
      final email = _formKey.currentState?.fields[AuthFormFields.email]?.value
              as String? ??
          '';
      _completedSuccessfully = true;
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
      _analytics
          .logEvent(AnalyticsEvents.authMethodSelected, {
            AnalyticsParams.authMethod: AnalyticsParams.authMethodEmail,
          })
          .ignore();
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
              ? ForgotPasswordEmailSentContent(
                  email: _sentEmail,
                  onResend: () => _handleResend(context),
                )
              : ForgotPasswordForm(
                  formKey: _formKey,
                  onSend: () => _handleSend(context),
                ),
        ),
      ),
    );
  }
}
