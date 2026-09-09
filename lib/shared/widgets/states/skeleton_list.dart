import 'package:flutter/material.dart';

import 'skeleton_box.dart';

/// Lista de placeholders de carga (shimmer), para pantallas con datos en
/// vuelo. Nunca un spinner.
class SkeletonList extends StatelessWidget {
  const SkeletonList({this.itemCount = 6, this.itemHeight = 72, super.key});

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return SkeletonBox(height: itemHeight, borderRadius: 20);
      },
    );
  }
}
