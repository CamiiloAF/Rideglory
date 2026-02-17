import 'package:flutter/material.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onSetAsCurrent;
  final VoidCallback? onAddMaintenance;
  final bool isCurrent;

  const VehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
    this.onDelete,
    this.onSetAsCurrent,
    this.onAddMaintenance,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: .06),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Gradient icon container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: .25),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        vehicle.vehicleType == VehicleType.motorcycle
                            ? Icons.two_wheeler_rounded
                            : Icons.directions_car_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  vehicle.name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: Color(0xFF10B981),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Principal',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (vehicle.brand != null ||
                              vehicle.model != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              [
                                vehicle.brand,
                                vehicle.model,
                              ].where((e) => e != null).join(' '),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onDelete != null)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: Colors.grey[600],
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 12),
                                const Text('Editar'),
                              ],
                            ),
                          ),
                          if (!isCurrent && onSetAsCurrent != null)
                            PopupMenuItem(
                              value: 'setCurrent',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 20,
                                    color: Colors.grey[700],
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Establecer como principal'),
                                ],
                              ),
                            ),
                          if (onAddMaintenance != null)
                            PopupMenuItem(
                              value: 'addMaintenance',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.build_circle_outlined,
                                    size: 20,
                                    color: Colors.grey[700],
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Agregar mantenimiento'),
                                ],
                              ),
                            ),
                          PopupMenuItem(
                            value: 'delete',
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Eliminar',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit' && onTap != null) {
                            onTap!();
                          } else if (value == 'setCurrent' &&
                              onSetAsCurrent != null) {
                            onSetAsCurrent!();
                          } else if (value == 'addMaintenance' &&
                              onAddMaintenance != null) {
                            onAddMaintenance!();
                          } else if (value == 'delete') {
                            onDelete!();
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Info chips section
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.speed_rounded,
                      label:
                          '${vehicle.currentMileage} ${vehicle.distanceUnit.label}',
                      color: const Color(0xFF6366F1),
                    ),
                    if (vehicle.year != null)
                      _InfoChip(
                        icon: Icons.calendar_today_rounded,
                        label: vehicle.year.toString(),
                        color: const Color(0xFF10B981),
                      ),
                    if (vehicle.licensePlate != null)
                      _InfoChip(
                        icon: Icons.badge_rounded,
                        label: vehicle.licensePlate!,
                        color: const Color(0xFFF59E0B),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: color,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
