import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/use_cases/get_events_use_case.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/usecases/get_vehicles_usecase.dart';

part 'home_state.dart';

@injectable
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._getEventsUseCase, this._getVehiclesUseCase)
    : super(const HomeInitial());

  final GetEventsUseCase _getEventsUseCase;
  final GetVehiclesUseCase _getVehiclesUseCase;

  Future<void> loadHomeData() async {
    emit(const HomeLoading());

    final vehiclesResult = await _getVehiclesUseCase();
    final eventsResult = await _getEventsUseCase();

    VehicleModel? mainVehicle;
    List<EventModel> upcomingEvents = [];

    vehiclesResult.fold((_) {}, (vehicles) {
      final active = vehicles.where((v) => !v.isArchived).toList();
      if (active.isNotEmpty) {
        mainVehicle = active.firstWhere(
          (v) => v.isMainVehicle,
          orElse: () => active.first,
        );
      }
    });

    eventsResult.fold((_) {}, (events) {
      final now = DateTime.now();
      upcomingEvents = events
          .where((e) => e.startDate.isAfter(now))
          .take(5)
          .toList();
    });

    emit(HomeLoaded(mainVehicle: mainVehicle, upcomingEvents: upcomingEvents));
  }
}
