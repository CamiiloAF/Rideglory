import 'package:flutter/material.dart';

import '../../../../shared/widgets/states/skeleton_box.dart';

/// Carga de la galería del garaje: shimmer de 4 celdas 2x2, nunca un
/// spinner.
///
/// Pencil: pBdbp
class GarageSkeletonGrid extends StatelessWidget {
  const GarageSkeletonGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => const SkeletonBox(height: 169, borderRadius: 20),
    );
  }
}
