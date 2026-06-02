import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/forgot_password_back_button.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/forgot_password_back_to_login_link.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/forgot_password_email_field.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/forgot_password_heading.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/forgot_password_send_button.dart';

class ForgotPasswordForm extends StatelessWidget {
  const ForgotPasswordForm({
    super.key,
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
          const Align(
            alignment: Alignment.centerLeft,
            child: ForgotPasswordBackButton(),
          ),
          const SizedBox(height: 32),
          const ForgotPasswordHeading(),
          const SizedBox(height: 32),
          ForgotPasswordEmailField(formKey: formKey),
          const SizedBox(height: 24),
          ForgotPasswordSendButton(onSend: onSend),
          const SizedBox(height: 24),
          const ForgotPasswordBackToLoginLink(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
