import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../tokens/app_colors.dart';
import 'internal/header_icon_button.dart';

/// Encabezado de página: volver, título centrado y acción opcional.
///
/// Pencil: AILBo
class AppPageHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppPageHeader({
    required this.title,
    this.onBack,
    this.actionIcon,
    this.onAction,
    super.key,
  });

  final String title;
  final VoidCallback? onBack;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          HeaderIconButton(
            icon: LucideIcons.arrowLeft,
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.text,
                ),
              ),
            ),
          ),
          if (actionIcon != null)
            HeaderIconButton(icon: actionIcon!, onPressed: onAction)
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}
