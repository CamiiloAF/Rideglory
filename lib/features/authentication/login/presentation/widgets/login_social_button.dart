import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';

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
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.darkSurfaceHighest,
        foregroundColor: context.colorScheme.onSurface,
        disabledForegroundColor: context.colorScheme.onSurface.withValues(
          alpha: 0.4,
        ),
        side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 13),
        textStyle: context.textTheme.titleSmall,
      ),
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }
}
