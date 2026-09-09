import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/result_state.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../../shared/widgets/states/error_state_view.dart';
import '../../domain/models/vehicle.dart';
import '../cubit/garage_gallery_cubit.dart';
import 'garage_empty_view.dart';
import 'garage_header.dart';
import 'garage_skeleton_grid.dart';
import 'vehicle_gallery_grid.dart';

/// Cuerpo de la pestaña Garaje: título fijo + contenido según
/// [ResultState] (skeleton, vacío, error con reintentar o la grilla).
class GarageGalleryView extends StatelessWidget {
  const GarageGalleryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const GarageHeader(),
        Expanded(
          child: BlocBuilder<GarageGalleryCubit, ResultState<List<Vehicle>>>(
            builder: (context, state) {
              return state.when(
                initial: () => const GarageSkeletonGrid(),
                loading: () => const GarageSkeletonGrid(),
                data: (vehicles) => VehicleGalleryGrid(vehicles: vehicles),
                empty: () => const GarageEmptyView(),
                error: (error) => ErrorStateView(
                  title: context.l10n.garage_error_title,
                  onRetry: () => context.read<GarageGalleryCubit>().load(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
