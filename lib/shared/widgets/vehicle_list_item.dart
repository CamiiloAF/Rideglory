import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/extensions/theme_extensions.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class VehicleListItem extends StatelessWidget {
  final VehicleModel vehicle;
  final bool isSelected;
  final VoidCallback onTap;

  const VehicleListItem({
    super.key,
    required this.vehicle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cs.surface.withOpacity(0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: context.appColors.primaryGradient,
                    )
                  : null,
              color: isSelected ? null : cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isSelected ? cs.surface.withOpacity(0) : cs.outlineVariant,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: cs.background.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.background.withOpacity(0.25)
                          : cs.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.motorcycle_rounded,
                      color: isSelected ? cs.onPrimary : cs.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.name,
                          style: context.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? cs.onPrimary
                                : cs.onSurface,
                          ),
                        ),
                        if (vehicle.brand != null || vehicle.model != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            [
                              vehicle.brand,
                              vehicle.model,
                            ].where((e) => e != null).join(' '),
                            style: context.bodySmall?.copyWith(
                              color: isSelected
                                  ? cs.onPrimary.withOpacity(0.7)
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (vehicle.licensePlate != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            vehicle.licensePlate!,
                            style: context.labelSmall?.copyWith(
                              color: isSelected
                                  ? cs.onPrimary.withOpacity(0.6)
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: cs.onPrimary,
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
