import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../design_system/components/app_secondary_button.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../l10n/l10n_extensions.dart';

/// Estado propio de esta app: sin conexión. Nunca una pantalla vacía; el
/// mensaje explica qué pasó y ofrece reintentar al recuperar señal.
class OfflineStateView extends StatelessWidget {
  const OfflineStateView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.wifiOff, size: 40, color: colors.textSecondary),
            const SizedBox(height: 16),
            Text(
              context.l10n.common_offline_title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.common_offline_body,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
            AppSecondaryButton(
              label: context.l10n.common_retry,
              onPressed: onRetry,
              icon: LucideIcons.refreshCw,
            ),
          ],
        ),
      ),
    );
  }
}
