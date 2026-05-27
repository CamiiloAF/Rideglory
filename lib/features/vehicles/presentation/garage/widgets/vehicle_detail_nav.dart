import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_detail_nav_button.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class VehicleDetailNav extends StatelessWidget {
  const VehicleDetailNav({
    super.key,
    required this.vehicle,
    required this.onBack,
  });

  final VehicleModel vehicle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              VehicleDetailNavButton(icon: Icons.arrow_back, onTap: onBack),
              Expanded(
                child: Text(
                  vehicle.name,
                  style: const TextStyle(
                    color: AppColors.textOnDarkPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              VehicleDetailNavButton(
                icon: Icons.edit_outlined,
                onTap: () => context.pushNamed(AppRoutes.editVehicle, extra: vehicle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
