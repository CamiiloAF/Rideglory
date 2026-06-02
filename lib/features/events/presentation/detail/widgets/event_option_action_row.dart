import 'package:flutter/material.dart';

/// A single tappable action row inside [EventOptionsBottomSheet]: a colored icon
/// circle followed by a label. Matches the Pencil "Event Detail — Menú Acciones"
/// action sheet design.
class EventOptionActionRow extends StatelessWidget {
  const EventOptionActionRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.labelColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ).copyWith(color: labelColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
