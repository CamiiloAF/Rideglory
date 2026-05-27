import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class ForgotPasswordEmailSentIcon extends StatelessWidget {
  const ForgotPasswordEmailSentIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          color: AppColors.primarySubtle,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.mail_outline_rounded,
          color: AppColors.primary,
          size: 40,
        ),
      ),
    );
  }
}
