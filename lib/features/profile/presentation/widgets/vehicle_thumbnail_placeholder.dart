import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/tokens/app_colors.dart';

/// Placeholder cuando la moto no tiene foto o falla al cargar.
class VehicleThumbnailPlaceholder extends StatelessWidget {
  const VehicleThumbnailPlaceholder({required this.colors, super.key});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.surface,
      alignment: Alignment.center,
      child: Icon(LucideIcons.bike, size: 22, color: colors.textSecondary),
    );
  }
}
