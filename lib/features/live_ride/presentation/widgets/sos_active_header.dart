import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Franja roja + volver + título de LV4a/LV4b/LV7 con SOS: siempre deja
/// claro, sin sutilezas, que hay una emergencia en curso.
///
/// Pencil: affuy + eWftM
class SosActiveHeader extends StatelessWidget implements PreferredSizeWidget {
  const SosActiveHeader({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: double.infinity, height: 8, color: colors.errorSolid),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.borderStrong),
                  ),
                  child: IconButton(
                    onPressed: onBack,
                    icon: Icon(
                      LucideIcons.arrowLeft,
                      size: 18,
                      color: colors.text,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  context.l10n.sos_active_header_title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.errorText,
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
      ],
    );
  }
}
