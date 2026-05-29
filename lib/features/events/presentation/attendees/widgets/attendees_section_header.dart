import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Encabezado de sección con contador, usado en "Gestionar Inscritos"
/// (nodos `sectionHeader` del diseño Pencil `IUxas`).
class AttendeesSectionHeader extends StatelessWidget {
  const AttendeesSectionHeader({
    super.key,
    required this.label,
    required this.labelColor,
    required this.count,
    required this.countBackgroundColor,
    required this.countTextColor,
  });

  final String label;
  final Color labelColor;
  final int count;
  final Color countBackgroundColor;
  final Color countTextColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        AppSpacing.hGapSm,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: countBackgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: countTextColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
