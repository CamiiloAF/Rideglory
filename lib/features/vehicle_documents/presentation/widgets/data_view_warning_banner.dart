import 'package:flutter/material.dart';

/// Warning banner rendered below the hero card in [DocumentDataView].
class DataViewWarningBanner extends StatelessWidget {
  const DataViewWarningBanner({
    super.key,
    required this.warning,
    required this.color,
  });

  final String warning;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              warning,
              style: TextStyle(color: color, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
