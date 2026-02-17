import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/list/cubit/vehicle_list_cubit.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/item_card/item_card.dart';

class ModernMaintenanceCard extends StatelessWidget {
  final MaintenanceModel maintenance;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ModernMaintenanceCard({
    super.key,
    required this.maintenance,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  Color get _typeColor {
    return maintenance.type == MaintenanceType.oilChange
        ? const Color(0xFF6366F1) // Indigo
        : const Color(0xFF8B5CF6); // Purple
  }

  IconData get _typeIcon {
    return maintenance.type == MaintenanceType.oilChange
        ? Icons.oil_barrel_rounded
        : Icons.build_circle_rounded;
  }

  double? _getProgressPercent(int? currentMileage) {
    final nextMaintenanceMileage = maintenance.nextMaintenanceMileage;

    if (nextMaintenanceMileage == null || currentMileage == null) return null;

    final totalDistance = nextMaintenanceMileage - maintenance.maintanceMileage;

    if (totalDistance <= 0) return 1.0;

    return currentMileage / nextMaintenanceMileage;
  }

  double? _getRemainingDistance(int? currentMileage) {
    if (currentMileage == null || maintenance.nextMaintenanceMileage == null) {
      return null;
    }
    final remaining = maintenance.nextMaintenanceMileage! - currentMileage;
    return remaining > 0 ? remaining : 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleCubit, VehicleState>(
      builder: (context, vehicleState) {
        final currentMileage = vehicleState is VehicleLoaded
            ? vehicleState.vehicle.currentMileage
            : null;

        return BlocBuilder<VehicleListCubit, ResultState<List<VehicleModel>>>(
          builder: (context, vehicleListState) {
            VehicleModel? maintenanceVehicle;
            if (maintenance.vehicleId != null &&
                vehicleListState is Data<List<VehicleModel>>) {
              try {
                maintenanceVehicle = vehicleListState.data.firstWhere(
                  (v) => v.id == maintenance.vehicleId,
                );
              } catch (e) {
                // Vehicle not found
              }
            }

            final daysUntilNext = maintenance.nextMaintenanceDate
                ?.difference(DateTime.now())
                .inDays;

            final progressPercent = _getProgressPercent(currentMileage);
            final isUrgent =
                (daysUntilNext != null && daysUntilNext < 10) ||
                (progressPercent != null && progressPercent >= 0.95);

            return _MaintenanceCardContent(
              maintenance: maintenance,
              maintenanceVehicle: maintenanceVehicle,
              typeColor: _typeColor,
              typeIcon: _typeIcon,
              currentMileage: currentMileage,
              progressPercent: progressPercent,
              isUrgent: isUrgent,
              daysUntilNext: daysUntilNext,
              getRemainingDistance: _getRemainingDistance,
              onTap: onTap,
              onEdit: onEdit,
              onDelete: onDelete,
            );
          },
        );
      },
    );
  }
}

class _MaintenanceCardContent extends StatelessWidget {
  final MaintenanceModel maintenance;
  final VehicleModel? maintenanceVehicle;
  final Color typeColor;
  final IconData typeIcon;
  final int? currentMileage;
  final double? progressPercent;
  final bool isUrgent;
  final int? daysUntilNext;
  final double? Function(int?) getRemainingDistance;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _MaintenanceCardContent({
    required this.maintenance,
    this.maintenanceVehicle,
    required this.typeColor,
    required this.typeIcon,
    required this.currentMileage,
    required this.progressPercent,
    required this.isUrgent,
    required this.daysUntilNext,
    required this.getRemainingDistance,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(maintenance.id ?? maintenance.hashCode.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Eliminar mantenimiento'),
              content: const Text(
                '¿Estás seguro de que deseas eliminar este mantenimiento? Esta acción no se puede deshacer.',
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Eliminar'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        onDelete?.call();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 32),
            SizedBox(height: 4),
            Text(
              'Eliminar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, typeColor.withValues(alpha: 0.05)],
        ),
        boxShadow: [
          BoxShadow(
            color: typeColor.withValues(alpha: .1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: MaintenanceCardHeader(
                          maintenance: maintenance,
                          typeColor: typeColor,
                          typeIcon: typeIcon,
                          isUrgent: isUrgent,
                        ),
                      ),
                      // Actions menu
                      if (onEdit != null || onDelete != null)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          itemBuilder: (context) => [
                            if (onEdit != null)
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 20),
                                    SizedBox(width: 12),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                            if (onDelete != null)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
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
                          onSelected: (value) async {
                            if (value == 'edit') {
                              onEdit?.call();
                            } else if (value == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext dialogContext) {
                                  return AlertDialog(
                                    title: const Text('Eliminar mantenimiento'),
                                    content: const Text(
                                      '¿Estás seguro de que deseas eliminar este mantenimiento? Esta acción no se puede deshacer.',
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(
                                          dialogContext,
                                        ).pop(false),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(
                                          dialogContext,
                                        ).pop(true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Eliminar'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (confirm == true) {
                                onDelete?.call();
                              }
                            }
                          },
                        ),
                    ],
                  ),
                  if (maintenanceVehicle != null) ...[
                    const SizedBox(height: 12),
                    _VehicleInfoChip(vehicle: maintenanceVehicle!),
                  ],
                  const SizedBox(height: 20),
                  MaintenanceMileageInfo(
                    maintenance: maintenance,
                    typeColor: typeColor,
                    currentMileage: currentMileage,
                    progressPercent: progressPercent,
                    getRemainingDistance: getRemainingDistance,
                  ),
                  const SizedBox(height: 16),
                  MaintenanceDatesSection(
                    maintenance: maintenance,
                    daysUntilNext: daysUntilNext,
                  ),
                  if (maintenance.notes != null &&
                      maintenance.notes!.isNotEmpty)
                    MaintenanceNotesSection(maintenance: maintenance),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleInfoChip extends StatelessWidget {
  final VehicleModel vehicle;

  const _VehicleInfoChip({required this.vehicle});

  IconData get _vehicleIcon {
    return vehicle.vehicleType == VehicleType.car
        ? Icons.directions_car_rounded
        : Icons.two_wheeler_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_vehicleIcon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(
            vehicle.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          if (vehicle.brand != null) ...[
            const SizedBox(width: 4),
            Text(
              '• ${vehicle.brand}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}
