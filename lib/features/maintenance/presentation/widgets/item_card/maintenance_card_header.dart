import 'package:flutter/material.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

class MaintenanceCardHeader extends StatelessWidget {
  final MaintenanceModel maintenance;
  final Color typeColor;
  final IconData typeIcon;
  final bool isUrgent;

  const MaintenanceCardHeader({
    super.key,
    required this.maintenance,
    required this.typeColor,
    required this.typeIcon,
    this.isUrgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [typeColor, typeColor.withValues(alpha: .7)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: typeColor.withValues(alpha: .3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(typeIcon, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                maintenance.name,
                style: context.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  maintenance.type.label,
                  style: context.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: typeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Badge de alerta
        if (maintenance.receiveAlert && isUrgent)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFFEF4444),
              size: 20,
            ),
          ),
      ],
    );
  }
}
