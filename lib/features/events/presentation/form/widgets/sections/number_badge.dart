import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Numbered circle badge for waypoint items in the custom route builder.
///
/// Design spec (Pencil veaGt):
/// - Size: 28×28, cornerRadius 14
/// - Index 1 (first): green fill #22C55E, white text (success green allows white)
/// - Last (index 9 / error): red fill #EF4444, white text
/// - Others (intermediate): orange fill #F98C1F, DARK text (#0D0D0F) per
///   Rideglory rule: text on accent must be dark
class NumberBadge extends StatelessWidget {
  const NumberBadge({super.key, required this.number});

  final int number;

  Color get _bgColor {
    if (number == 1) return AppColors.success;
    if (number == 9) return AppColors.error;
    return AppColors.primary;
  }

  Color get _fgColor {
    // Only on the accent orange do we use dark text; green and red use white.
    if (number == 1) return Colors.white;
    if (number == 9) return Colors.white;
    return AppColors.darkBgPrimary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: _bgColor, shape: BoxShape.circle),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            color: _fgColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
