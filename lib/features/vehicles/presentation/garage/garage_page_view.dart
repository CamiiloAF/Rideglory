import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_vehicles_content.dart';
import 'package:rideglory/shared/router/app_routes.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.loadVehicles();
    });
  }

  void _onSelectVehicle(VehicleModel vehicle) {
    context.pushNamed(AppRoutes.vehicleDetail, extra: vehicle).then((_) {
      // After returning from detail, reload in case the vehicle was edited.
      if (mounted) widget.loadVehicles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleCubit, ResultState<List<VehicleModel>>>(
      builder: (context, state) {
        // Tratamos `Initial` como `Loading` para no mostrar por un instante la
        // pantalla vacía antes de que arranque la primera carga.
        if (state is Loading || state is Initial) {
          return PageLoadingStateWidget(onRefresh: widget.loadVehicles);
        }
        if (state is Error<List<VehicleModel>>) {
          return PageErrorStateWidget(
            title: context.l10n.errorOccurred,
            message: context.l10n.errorMessage(state.error.message),
            onRetry: widget.loadVehicles,
            onRefresh: widget.loadVehicles,
          );
        }

        return GarageVehiclesContent(
          loadVehicles: widget.loadVehicles,
          openWithVehicleId: widget.openWithVehicleId,
          onSelectVehicle: _onSelectVehicle,
          onMaintenanceCreated: (_) {},
          onMaintenanceRefreshRequested: (_) {},
        );
      },
    );
  }
}
