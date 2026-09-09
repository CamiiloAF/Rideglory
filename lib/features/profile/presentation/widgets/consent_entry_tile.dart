import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/consent_entry.dart';
import '../consent_kind_label.dart';

/// Una fila de "Mis consentimientos": tipo, versión y fecha de aceptación.
class ConsentEntryTile extends StatelessWidget {
  const ConsentEntryTile({required this.entry, super.key});

  final ConsentEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final dateFormat = DateFormat('d MMM y, HH:mm', 'es_CO');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.checkCheck, size: 18, color: colors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  consentKindLabel(context, entry.kind),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${context.l10n.profile_consent_version_label(entry.version)} · '
                  '${dateFormat.format(entry.acceptedAt)}',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
