import 'package:flutter/material.dart';

import '../../../../shared/widgets/states/skeleton_box.dart';

/// Shimmer de la fila "MIS MOTOS" mientras carga.
class VehiclesRowSkeleton extends StatelessWidget {
  const VehiclesRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: SkeletonBox(height: 76, borderRadius: 16)),
        SizedBox(width: 10),
        Expanded(child: SkeletonBox(height: 76, borderRadius: 16)),
        SizedBox(width: 10),
        Expanded(child: SkeletonBox(height: 76, borderRadius: 16)),
      ],
    );
  }
}
