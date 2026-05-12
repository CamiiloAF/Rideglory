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

  void updateEvent(EventModel event) {
    final current = state;
    if (current is! HomeLoaded) return;
    final updated = current.upcomingEvents
        .map((e) => e.id == event.id ? event : e)
        .toList(growable: false);
    emit(
      HomeLoaded(mainVehicle: current.mainVehicle, upcomingEvents: updated),
    );
  }

  void removeEvent(String eventId) {
    final current = state;
    if (current is! HomeLoaded) return;
    final updated = current.upcomingEvents
        .where((e) => e.id != eventId)
        .toList(growable: false);
    emit(
      HomeLoaded(mainVehicle: current.mainVehicle, upcomingEvents: updated),
    );
  }
}
