import 'package:flutter/material.dart';

import '../../../../shared/widgets/states/skeleton_box.dart';

/// Carga del resumen de borrado de cuenta (paso 1).
class DeleteAccountSummarySkeleton extends StatelessWidget {
  const DeleteAccountSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: SkeletonBox(height: 320, borderRadius: 20),
    );
  }
}
