import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/services/image_storage_service.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/delete/cubit/vehicle_action_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/form/widgets/vehicle_form_view.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';

class VehicleFormPage extends StatelessWidget {
  const VehicleFormPage({super.key, this.vehicle});

  final VehicleModel? vehicle;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              FormImageCubit(getIt<ImageStorageService>())
                ..initialize(remoteImageUrl: vehicle?.imageUrl),
        ),
        BlocProvider(
          create: (context) =>
              getIt.get<VehicleFormCubit>()..initialize(vehicle: vehicle),
        ),
        BlocProvider(
          create: (context) => getIt<VehicleActionCubit>()..reset(),
        ),
      ],
      child: const VehicleFormView(),
    );
  }
}
