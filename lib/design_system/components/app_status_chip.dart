import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';

/// Tono semántico de un [AppStatusChip] / [AppPhotoChip].
enum AppStatusTone { warning, error, success }

/// Chip de estado sobre superficie (fondo `-soft`, texto/ícono del tono).
///
/// Pencil: epyf0
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    required this.icon,
    required this.label,
    required this.tone,
    super.key,
  });

  final IconData icon;
  final String label;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final (background, foreground) = switch (tone) {
      AppStatusTone.warning => (colors.warningSoft, colors.warning),
      AppStatusTone.error => (colors.errorSoft, colors.errorText),
      AppStatusTone.success => (colors.successSoft, colors.success),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
