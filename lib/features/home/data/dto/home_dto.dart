import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rideglory/features/events/data/dto/event_dto.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/home/domain/models/home_data.dart';
import 'package:rideglory/features/vehicles/data/dto/vehicle_dto.dart';

part 'home_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class HomeDto {
  const HomeDto({this.mainVehicle, required this.upcomingEvents});

  final VehicleDto? mainVehicle;
  final List<EventDto> upcomingEvents;

  factory HomeDto.fromJson(Map<String, dynamic> json) =>
      _$HomeDtoFromJson(json);

  Map<String, dynamic> toJson() => _$HomeDtoToJson(this);

  HomeData toHomeData() => HomeData(
    mainVehicle: mainVehicle,
    upcomingEvents: List<EventModel>.from(upcomingEvents),
  );
}
