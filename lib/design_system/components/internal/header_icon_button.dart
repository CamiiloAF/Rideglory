import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_radii.dart';

/// Botón de icono 48x48 usado dentro de [AppPageHeader].
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({required this.icon, this.onPressed, super.key});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 22, color: colors.text),
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
        ),
      ),
    );
  }
}
