import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_archived_header.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_other_vehicle_item.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class GarageArchivedSection extends StatefulWidget {
  const GarageArchivedSection({
    super.key,
    required this.archivedVehicles,
    this.onGarageListUpdatedLocally,
    this.initiallyExpanded = false,
  });

  final List<VehicleModel> archivedVehicles;
  final void Function([VehicleModel?])? onGarageListUpdatedLocally;
  final bool initiallyExpanded;

  @override
  State<GarageArchivedSection> createState() => _GarageArchivedSectionState();
}

class _GarageArchivedSectionState extends State<GarageArchivedSection> {
  late bool _isExpanded = widget.initiallyExpanded;

  @override
  void didUpdateWidget(GarageArchivedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.archivedVehicles.isEmpty &&
        widget.archivedVehicles.isNotEmpty) {
      _isExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.archivedVehicles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        GarageArchivedHeader(
          count: widget.archivedVehicles.length,
          isExpanded: _isExpanded,
          onTap: () => setState(() => _isExpanded = !_isExpanded),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 12),
          ...widget.archivedVehicles.map(
            (vehicle) => Padding(
              key: ValueKey(vehicle.id),
              padding: const EdgeInsets.only(bottom: 12),
              child: GarageOtherVehicleItem(
                vehicle: vehicle,
                onTap: () =>
                    context.pushNamed(AppRoutes.vehicleDetail, extra: vehicle),
                onOptionsTap: () => GarageOptionsBottomSheet.show(
                  context,
                  vehicle,
                  onGarageListUpdatedLocally: widget.onGarageListUpdatedLocally,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
