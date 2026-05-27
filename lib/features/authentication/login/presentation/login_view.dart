import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/constants/auth_form_fields.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/login_brand_header.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/login_divider.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/login_form.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/login_heading.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/login_register_row.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/login_social_section.dart';
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
                  const LoginBrandHeader(),
                  const SizedBox(height: 40),
                  const LoginHeading(),
                  const SizedBox(height: 32),
                  LoginForm(
                    formKey: _formKey,
                    isLoading: _emailLoading,
                    onLogin: () => _handleLogin(context),
                  ),
                  const SizedBox(height: 24),
                  const LoginDivider(),
                  const SizedBox(height: 24),
                  const LoginSocialSection(),
                  const SizedBox(height: 32),
                  const LoginRegisterRow(),
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
