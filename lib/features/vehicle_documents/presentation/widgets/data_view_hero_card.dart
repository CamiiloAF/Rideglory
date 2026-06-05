import 'package:flutter/material.dart';

/// Hero status card rendered at the top of [DocumentDataView].
class DataViewHeroCard extends StatelessWidget {
  const DataViewHeroCard({
    super.key,
    required this.heroColor,
    required this.heroIcon,
    required this.heroTitle,
    this.heroDaysChip,
  });

  final Color heroColor;
  final IconData heroIcon;
  final String heroTitle;
  final String? heroDaysChip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: heroColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: heroColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(heroIcon, color: heroColor, size: 48),
          const SizedBox(height: 12),
          Text(
            heroTitle,
            style: TextStyle(
              color: heroColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (heroDaysChip != null && heroDaysChip!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: heroColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                heroDaysChip!,
                style: TextStyle(
                  color: heroColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
