import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../tokens/app_colors.dart';
import 'app_status_chip.dart';

/// Fila de un registro de mantenimiento: icono, título/subtítulo,
/// cifras a la derecha y una nota de duración opcional debajo.
///
/// Pencil: lnyll
class RecordRow extends StatelessWidget {
  const RecordRow({
    required this.title,
    required this.subtitle,
    required this.primaryValue,
    this.secondaryValue,
    this.durationNote,
    this.icon = LucideIcons.wrench,
    this.onTap,
    this.tone,
    super.key,
  });

  final String title;
  final String subtitle;
  final String primaryValue;
  final String? secondaryValue;
  final String? durationNote;
  final IconData icon;
  final VoidCallback? onTap;

  /// Urgencia del registro (agenda). `null` = neutro (historial).
  final AppStatusTone? tone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final (iconBackground, iconForeground, valueColor) = switch (tone) {
      null => (colors.surface, colors.text, colors.text),
      AppStatusTone.error => (
        colors.errorSoft,
        colors.errorText,
        colors.errorText,
      ),
      AppStatusTone.warning => (
        colors.warningSoft,
        colors.warning,
        colors.warning,
      ),
      AppStatusTone.success => (
        colors.successSoft,
        colors.success,
        colors.success,
      ),
    };
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: tone == null
                        ? Border.all(color: colors.borderStrong)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 20, color: iconForeground),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      primaryValue,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: valueColor,
                      ),
                    ),
                    if (secondaryValue != null)
                      Text(
                        secondaryValue!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: colors.textSecondary,
                ),
              ],
            ),
            if (durationNote != null) ...[
              const SizedBox(height: 9),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.accent),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.timer, size: 12, color: colors.text),
                    const SizedBox(width: 6),
                    Text(
                      durationNote!,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
