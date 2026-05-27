import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/shared/widgets/vehicle_selection_bottom_sheet.dart';

class MaintenanceVehicleSelector extends StatelessWidget {
  final VehicleModel selectedVehicle;
  final List<VehicleModel> availableVehicles;
  final ValueChanged<VehicleModel> onVehicleChanged;

  const MaintenanceVehicleSelector({
    super.key,
    required this.selectedVehicle,
    required this.availableVehicles,
    required this.onVehicleChanged,
  });

  Future<void> _onTap(BuildContext context) async {
    final result = await VehicleSelectionBottomSheet.show(
      context: context,
      vehicles: availableVehicles,
      selectedVehicleId: selectedVehicle.id,
    );
    if (result != null) {
      onVehicleChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorderPrimary),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.two_wheeler,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedVehicle.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Cambiar vehículo',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textOnDarkTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textOnDarkSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
