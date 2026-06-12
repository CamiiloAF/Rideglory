import 'package:flutter/material.dart';

/// A single shimmer skeleton row used in [SearchSkeletonList].
class SkeletonRow extends StatelessWidget {
  const SkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
