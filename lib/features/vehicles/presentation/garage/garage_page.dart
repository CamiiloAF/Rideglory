import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/garage/garage_page_view.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class GaragePage extends StatelessWidget {
  const GaragePage({super.key});

  Future<void> _loadMyVehicles(BuildContext context) {
    return context.read<VehicleCubit>().fetchMyVehicles();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) {
        if (!didPop) context.goNamed(AppRoutes.home);
      },
      child: Builder(
        builder: (context) {
          return GaragePageView(
            loadVehicles: () => _loadMyVehicles(context),
          );
        },
      ),
    );
  }
}
