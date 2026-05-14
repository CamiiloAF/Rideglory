import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class VehicleSelectionBottomSheet extends StatelessWidget {
  final String? subtitle;
  final List<VehicleModel> vehicles;
  final String? selectedVehicleId;

  const VehicleSelectionBottomSheet({
    super.key,
    this.subtitle,
    required this.vehicles,
    this.selectedVehicleId,
  });

  static Future<VehicleModel?> show({
    required BuildContext context,
    String? subtitle,
    required List<VehicleModel> vehicles,
    String? selectedVehicleId,
  }) {
    return showModalBottomSheet<VehicleModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VehicleSelectionBottomSheet(
        subtitle: subtitle,
        vehicles: vehicles,
        selectedVehicleId: selectedVehicleId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.darkBorderPrimary),
          left: BorderSide(color: AppColors.darkBorderPrimary),
          right: BorderSide(color: AppColors.darkBorderPrimary),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.darkBorderPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.vehicle_selectVehicle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.textOnDarkSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // Vehicles list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              itemCount: vehicles.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.darkBorderPrimary),
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                final isSelected = vehicle.id == selectedVehicleId;

                return _VehicleSheetItem(
                  vehicle: vehicle,
                  isSelected: isSelected,
                  onTap: () => Navigator.pop(context, vehicle),
                );
              },
            ),
          ),

          // Add new vehicle link
          const Divider(height: 1, color: AppColors.darkBorderPrimary),
          GestureDetector(
            onTap: () async {
              Navigator.pop(context);
              await context.pushNamed(AppRoutes.createVehicle);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  const Icon(Icons.add, color: AppColors.primary, size: 20),
                  AppSpacing.hGapSm,
                  Text(
                    context.l10n.vehicle_addVehicle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _VehicleSheetItem extends StatelessWidget {
  const _VehicleSheetItem({
    required this.vehicle,
    required this.isSelected,
    required this.onTap,
  });

  final VehicleModel vehicle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const Icon(
              Icons.two_wheeler,
              size: 24,
              color: AppColors.textOnDarkSecondary,
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    [vehicle.licensePlate, vehicle.year?.toString()]
                        .where((e) => e != null && e.isNotEmpty)
                        .join(' · '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textOnDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Radio button
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.darkBorderPrimary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, size: 12, color: Colors.white),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
