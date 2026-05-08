import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/use_cases/get_events_use_case.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

part 'home_state.dart';

@injectable
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._getEventsUseCase) : super(const HomeInitial());

  final GetEventsUseCase _getEventsUseCase;

  Future<void> loadHomeData() async {
    emit(const HomeLoading());

    final eventsResult = await _getEventsUseCase();

    const VehicleModel? mainVehicle = null;
    List<EventModel> upcomingEvents = [];

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
