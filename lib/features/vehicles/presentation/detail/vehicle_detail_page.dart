import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart';

/// Full-screen vehicle detail page, opened via [AppRoutes.vehicleDetail].
///
/// Accepts a [VehicleModel] as route `extra`. Manages maintenance refresh
/// state internally so the page is self-contained and the bottom nav bar
/// is not shown.
class VehicleDetailPage extends StatefulWidget {
  final VehicleModel vehicle;

  const VehicleDetailPage({super.key, required this.vehicle});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  late VehicleModel _vehicle;
  int _maintenanceRefreshTick = 0;
  final Map<String, MaintenanceModel> _pendingMaintenanceByVehicleId = {};

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
  }

  void _onMaintenanceCreated(MaintenanceModel maintenance) {
    final vehicleId = maintenance.vehicleId;
    if (vehicleId == null) return;
    setState(() {
      _maintenanceRefreshTick += 1;
      _pendingMaintenanceByVehicleId[vehicleId] = maintenance;
    });
  }

  void _onPendingMaintenanceConsumed(String vehicleId) {
    if (!_pendingMaintenanceByVehicleId.containsKey(vehicleId)) return;
    setState(() => _pendingMaintenanceByVehicleId.remove(vehicleId));
  }

  void _onMaintenanceRefreshRequested(String vehicleId) {
    setState(() {
      _maintenanceRefreshTick += 1;
      _pendingMaintenanceByVehicleId.remove(vehicleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // El VehicleCubit (singleton) es la fuente de verdad del odómetro: al crear
    // un mantenimiento se actualiza allí, así que sincronizamos el km del detalle
    // para reflejarlo sin tener que recargar la pantalla.
    return BlocListener<VehicleCubit, ResultState<List<VehicleModel>>>(
      listener: (context, state) {
        state.whenOrNull(
          data: (vehicles) {
            final fresh = vehicles
                .where((vehicle) => vehicle.id == _vehicle.id)
                .firstOrNull;
            if (fresh != null &&
                fresh.currentMileage != _vehicle.currentMileage) {
              setState(
                () => _vehicle = _vehicle.copyWith(
                  currentMileage: fresh.currentMileage,
                ),
              );
            }
          },
        );
      },
      child: VehicleDetailView(
        vehicle: _vehicle,
        onBack: () => context.pop(),
        maintenanceRefreshTick: _maintenanceRefreshTick,
        pendingCreatedMaintenance: _pendingMaintenanceByVehicleId[_vehicle.id],
        onPendingMaintenanceConsumed: _onPendingMaintenanceConsumed,
        onMaintenanceCreated: _onMaintenanceCreated,
        onMaintenanceRefreshRequested: _onMaintenanceRefreshRequested,
        onVehicleUpdated: (updated) => setState(() => _vehicle = updated),
      ),
    );
  }
}
