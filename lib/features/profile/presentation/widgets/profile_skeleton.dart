import 'package:flutter/material.dart';

import '../../../../shared/widgets/states/skeleton_box.dart';

/// Carga de P2: mismo esqueleto de identidad + motos + ajustes, con
/// shimmer en vez de spinner.
///
/// Pencil: ZhLW3
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: const [
        Row(
          children: [
            SkeletonBox(width: 64, height: 64, borderRadius: 24),
            SizedBox(width: 14),
            Expanded(child: SkeletonBox(height: 16)),
          ],
        ),
        SizedBox(height: 18),
        SkeletonBox(height: 110, borderRadius: 20),
        SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 76, borderRadius: 16)),
            SizedBox(width: 10),
            Expanded(child: SkeletonBox(height: 76, borderRadius: 16)),
            SizedBox(width: 10),
            Expanded(child: SkeletonBox(height: 76, borderRadius: 16)),
          ],
        ),
        SizedBox(height: 18),
        SkeletonBox(height: 200, borderRadius: 20),
      ],
    );
  }
}
