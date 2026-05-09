import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/home/domain/use_cases/get_home_data_use_case.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

part 'home_state.dart';

@injectable
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._getHomeDataUseCase) : super(const HomeInitial());

  final GetHomeDataUseCase _getHomeDataUseCase;

  Future<void> loadHomeData() async {
    emit(const HomeLoading());

    final result = await _getHomeDataUseCase();

    result.fold(
      (error) => emit(HomeError(error.message)),
      (data) => emit(
        HomeLoaded(
          mainVehicle: data.mainVehicle,
          upcomingEvents: data.upcomingEvents,
        ),
      ),
    );
  }
}
