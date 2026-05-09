import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class HomeData {
  const HomeData({
    this.mainVehicle,
    required this.upcomingEvents,
  });

  final VehicleModel? mainVehicle;
  final List<EventModel> upcomingEvents;
}
