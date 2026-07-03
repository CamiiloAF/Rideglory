import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class WaypointPreviewRow extends StatelessWidget {
  const WaypointPreviewRow({
    super.key,
    required this.index,
    required this.name,
    required this.isLast,
  });

  final int index;
  final String name;
  final bool isLast;

  Color get _dotColor {
    if (index == 0) return AppColors.success;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textOnDarkPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Container(height: 1, color: AppColors.darkBorderPrimary),
      ],
    );
  }
}
