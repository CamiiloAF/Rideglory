import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_banner.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Reemplaza el paso 3 mientras se publica o si falló (`f2Atae`/`n6FeR9`).
/// El formulario no se pierde: sigue en el cubit, solo se oculta mientras
/// dura la operación.
class CreateEventSavingView extends StatelessWidget {
  const CreateEventSavingView({required this.hasError, super.key});

  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasError) ...[
            AppBanner(
              icon: LucideIcons.alertTriangle,
              title: context.l10n.events_create_error_title,
              body: context.l10n.events_create_error_body,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            context.l10n.events_create_step3_title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.events_create_saving_subtitle,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
