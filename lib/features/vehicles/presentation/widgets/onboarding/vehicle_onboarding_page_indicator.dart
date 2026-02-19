import 'package:flutter/material.dart';

class VehicleOnboardingPageIndicator extends StatelessWidget {
  final int totalPages;
  final int currentPage;

  const VehicleOnboardingPageIndicator({
    super.key,
    required this.totalPages,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          totalPages,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: currentPage == index
                  ? const Color(0xFF6366F1)
                  : Colors.grey[300],
            ),
          ),
        ),
      ),
    );
  }
}
