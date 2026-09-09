import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/get_rider_vehicle_previews_usecase.dart';
import 'profile_overview_state.dart';

/// Carga en paralelo el perfil y las motos del rider para P2.
@injectable
class ProfileOverviewCubit extends Cubit<ProfileOverviewState> {
  ProfileOverviewCubit(this._getProfile, this._getRiderVehiclePreviews)
    : super(ProfileOverviewState.initial());

  final GetProfileUseCase _getProfile;
  final GetRiderVehiclePreviewsUseCase _getRiderVehiclePreviews;

  Future<void> load() async {
    emit(
      state.copyWith(
        profile: const ResultState.loading(),
        vehicles: const ResultState.loading(),
      ),
    );
    // Se lanzan ambas peticiones antes de esperar la primera, para que
    // corran en paralelo sin perder el tipo estático de cada `Either`.
    final profileFuture = _getProfile();
    final vehiclesFuture = _getRiderVehiclePreviews();

    final profileResult = await profileFuture;
    emit(
      state.copyWith(
        profile: profileResult.fold(
          (error) => ResultState.error(error: error),
          (profile) => ResultState.data(data: profile),
        ),
      ),
    );

    final vehiclesResult = await vehiclesFuture;
    emit(
      state.copyWith(
        vehicles: vehiclesResult.fold(
          (error) => ResultState.error(error: error),
          (vehicles) => vehicles.isEmpty
              ? const ResultState.empty()
              : ResultState.data(data: vehicles),
        ),
      ),
    );
  }
}
