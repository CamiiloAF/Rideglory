import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_vehicles_content.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/states/page_error_state_widget.dart';
import 'package:rideglory/shared/widgets/states/page_loading_state_widget.dart';

class GaragePageView extends StatefulWidget {
  const GaragePageView({super.key, required this.loadVehicles});

  final Future<void> Function() loadVehicles;

  @override
  State<GaragePageView> createState() => _GaragePageViewState();
}

class _GaragePageViewState extends State<GaragePageView> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.loadVehicles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(Icons.two_wheeler, color: context.colorScheme.primary),
        ),
        title: Text(
          context.l10n.vehicle_myGarage,
          style: context.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.notifications_none,
                color: context.colorScheme.primary,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<VehicleCubit, ResultState<List<VehicleModel>>>(
          builder: (context, state) {
            return state.maybeWhen(
              loading: () =>
                  PageLoadingStateWidget(onRefresh: widget.loadVehicles),
              error: (error) => PageErrorStateWidget(
                title: context.l10n.errorOccurred,
                message: context.l10n.errorMessage(error.message),
                onRetry: widget.loadVehicles,
                onRefresh: widget.loadVehicles,
              ),
              empty: () => EmptyStateWidget(
                icon: Icons.garage_outlined,
                title: context.l10n.vehicle_noVehicles,
                description: context.l10n.vehicle_noVehiclesDescription,
                actionButtonText: context.l10n.vehicle_addVehicle,
                onActionPressed: () =>
                    context.pushNamed(AppRoutes.createVehicle),
              ),
              data: (_) => GarageVehiclesContent(
                currentIndex: _currentIndex,
                onIndexChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
              orElse: () => const PageLoadingStateWidget(),
            );
          },
        ),
      ),
    );
  }
}
