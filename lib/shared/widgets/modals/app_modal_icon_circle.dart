import 'package:flutter/material.dart';

/// Glowing circular icon badge used at the top of [AppModal].
///
/// Matches the Pencil `Component/Modal` icon section: a 60x60 circle with a
/// variant-specific surface fill, a soft accent glow, and a centered 28px icon
/// rendered in the modal accent color.
class AppModalIconCircle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color circleFill;
  final Color glowColor;
  final double glowBlur;
  final double glowSpread;

  const AppModalIconCircle({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.circleFill,
    required this.glowColor,
    this.glowBlur = 24,
    this.glowSpread = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: circleFill,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: glowBlur,
            spreadRadius: glowSpread,
          ),
        ],
      ),
      child: Icon(icon, color: iconColor, size: 28),
    );
  }
}
