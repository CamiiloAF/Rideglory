import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import 'app_status_chip.dart';

/// Chip de estado superpuesto sobre una foto (fondo `$c-plate` translúcido).
///
/// Pencil: t9b7A
class AppPhotoChip extends StatelessWidget {
  const AppPhotoChip({
    required this.icon,
    required this.label,
    this.tone = AppStatusTone.error,
    super.key,
  });

  final IconData icon;
  final String label;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final foreground = switch (tone) {
      AppStatusTone.warning => colors.warningOnBlock,
      AppStatusTone.error => colors.errorOnBlock,
      AppStatusTone.success => colors.successOnBlock,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.plate,
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
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: colors.plateText,
            ),
          ),
        ],
      ),
    );
  }
}
