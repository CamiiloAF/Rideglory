import 'package:flutter/material.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/skeleton_row.dart';
import 'package:shimmer/shimmer.dart';

/// 3-row shimmer skeleton for autocomplete loading state.
///
/// Displayed inside [AppPlaceSuggestionsDropdown] when [isLoading] is true.
class SearchSkeletonList extends StatelessWidget {
  const SearchSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF383838),
      highlightColor: const Color(0xFF505050),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) => const SkeletonRow()),
      ),
    );
  }
}
