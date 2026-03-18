part of 'home_cubit.dart';

sealed class HomeState {
  const HomeState();
}

final class HomeInitial extends HomeState {
  const HomeInitial();
}

final class HomeLoading extends HomeState {
  const HomeLoading();
}

final class HomeLoaded extends HomeState {
  const HomeLoaded({this.mainVehicle, required this.upcomingEvents});

  final VehicleModel? mainVehicle;
  final List<EventModel> upcomingEvents;
}

final class HomeError extends HomeState {
  const HomeError(this.message);

  final String message;
}
