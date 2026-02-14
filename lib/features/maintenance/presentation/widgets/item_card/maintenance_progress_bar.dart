import 'package:flutter/material.dart';

/// Widget para mostrar la barra de progreso del mantenimiento
class MaintenanceProgressBar extends StatelessWidget {
  final Color typeColor;
  final double progressPercent;

  const MaintenanceProgressBar({
    super.key,
    required this.typeColor,
    required this.progressPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        FractionallySizedBox(
          widthFactor: progressPercent,
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [typeColor, typeColor.withValues(alpha: .7)],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}
