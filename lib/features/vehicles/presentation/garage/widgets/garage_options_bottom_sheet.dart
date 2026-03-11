import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_strings.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class GarageOptionsBottomSheet extends StatelessWidget {
  const GarageOptionsBottomSheet({super.key, required this.vehicle});

  final VehicleModel vehicle;

  static void show(BuildContext context, VehicleModel vehicle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) =>
          GarageOptionsBottomSheet(vehicle: vehicle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.white),
            title: Text(
              VehicleStrings.editVehicle,
              style: context.bodyLarge?.copyWith(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              context.pushNamed(AppRoutes.editVehicle, extra: vehicle);
            },
          ),
          ListTile(
            leading: const Icon(Icons.build, color: AppColors.primary),
            title: Text(
              VehicleStrings.addMaintenance,
              style: context.bodyLarge?.copyWith(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              context.pushNamed(AppRoutes.createMaintenance, extra: vehicle);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text(
              VehicleStrings.deleteVehicle,
              style: context.bodyLarge?.copyWith(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              context.read<VehicleCubit>().deleteVehicleLocally(vehicle.id!);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
