import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_radii.dart';

/// Bloque de carga con shimmer. Nunca uses un spinner para representar
/// "cargando contenido de lista/detalle" — eso es este widget.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    this.width,
    this.height = 16,
    this.borderRadius = AppRadii.sm,
    super.key,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Shimmer.fromColors(
      baseColor: colors.surface,
      highlightColor: colors.border,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
