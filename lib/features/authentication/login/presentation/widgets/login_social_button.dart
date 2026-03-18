import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class LoginSocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const LoginSocialButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      onPressed: onPressed,
      label: label,
      icon: icon,
      variant: AppButtonVariant.primary,
      style: AppButtonStyle.outlined,
      isFullWidth: true,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 13,
      ),
    );
  }
}
