import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_vehicles_content.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart';
import 'package:rideglory/shared/widgets/states/page_error_state_widget.dart';
import 'package:rideglory/shared/widgets/states/page_loading_state_widget.dart';

class GaragePageView extends StatefulWidget {
  const GaragePageView({
    super.key,
    required this.loadVehicles,
    this.openWithVehicleId,
  });

  final Future<void> Function() loadVehicles;
  final String? openWithVehicleId;

  @override
  State<GaragePageView> createState() => _GaragePageViewState();
}

class _GaragePageViewState extends State<GaragePageView> {
  VehicleModel? _selectedVehicle;
  int _maintenanceRefreshTick = 0;
  final Map<String, MaintenanceModel> _pendingMaintenanceByVehicleId = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.loadVehicles();
    });
  }

  void _selectVehicle(VehicleModel vehicle) => setState(() => _selectedVehicle = vehicle);
  void _clearSelection() => setState(() => _selectedVehicle = null);

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
    return BlocBuilder<VehicleCubit, ResultState<List<VehicleModel>>>(
      builder: (context, state) {
        if (state is Loading) return PageLoadingStateWidget(onRefresh: widget.loadVehicles);
        if (state is Error<List<VehicleModel>>) {
          return PageErrorStateWidget(
            title: context.l10n.errorOccurred,
            message: context.l10n.errorMessage(state.error.message),
            onRetry: widget.loadVehicles,
            onRefresh: widget.loadVehicles,
          );
        }

        final selected = _selectedVehicle;
        if (selected != null) {
          // Sync in case the vehicle was edited/updated
          final vehicles = context.read<VehicleCubit>().availableVehicles;
          final updated = vehicles.where((v) => v.id == selected.id).firstOrNull ?? selected;

          return VehicleDetailView(
            vehicle: updated,
            onBack: _clearSelection,
            maintenanceRefreshTick: _maintenanceRefreshTick,
            pendingCreatedMaintenance: _pendingMaintenanceByVehicleId[updated.id],
            onPendingMaintenanceConsumed: _onPendingMaintenanceConsumed,
            onMaintenanceCreated: _onMaintenanceCreated,
            onMaintenanceRefreshRequested: _onMaintenanceRefreshRequested,
            onVehicleUpdated: (v) => setState(() => _selectedVehicle = v),
          );
        }

        return GarageVehiclesContent(
          loadVehicles: widget.loadVehicles,
          openWithVehicleId: widget.openWithVehicleId,
          onSelectVehicle: _selectVehicle,
          onMaintenanceCreated: _onMaintenanceCreated,
          onMaintenanceRefreshRequested: _onMaintenanceRefreshRequested,
        );
      },
    );
  }
}
