import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class NumberBadge extends StatelessWidget {
  const NumberBadge({super.key, required this.number});

  final int number;

  Color get _color {
    if (number == 1) return AppColors.success;
    if (number == 9) return AppColors.error;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
