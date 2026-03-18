import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleSelector extends StatelessWidget {
  const VehicleSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleCubit, VehicleState>(
      builder: (context, vehicleState) {
        final vehicleCubit = context.read<VehicleCubit>();
        final currentVehicle = vehicleCubit.currentVehicle;
        final vehicles = vehicleCubit.availableVehicles
            .where((v) => !v.isArchived)
            .toList();

        if (vehicles.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<VehicleModel>(
                    value: currentVehicle,
                    isExpanded: true,
                    hint: Text(context.l10n.vehicle_selectVehicle),
                    items: vehicles.map((vehicle) {
                      return DropdownMenuItem<VehicleModel>(
                        value: vehicle,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              vehicle.name,
                              style: context.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (vehicle.brand != null || vehicle.model != null)
                              Text(
                                [
                                  vehicle.brand,
                                  vehicle.model,
                                ].where((e) => e != null).join(' '),
                                style: context.bodySmall,
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (vehicle) async {
                      if (vehicle != null) {
                        await vehicleCubit.setCurrentVehicle(vehicle);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
