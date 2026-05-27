import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/forgot_password_email_sent_icon.dart';

class ForgotPasswordEmailSentContent extends StatelessWidget {
  const ForgotPasswordEmailSentContent({
    super.key,
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
          const ForgotPasswordEmailSentIcon(),
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
            onPressed: () => context.pop(),
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
