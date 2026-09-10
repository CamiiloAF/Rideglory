import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/live_ride_contacts.dart';
import '../../domain/live_rider.dart';
import '../../domain/location_permission_state.dart';
import '../../domain/rider_position.dart';
import 'sharing_status.dart';

part 'live_ride_state.freezed.dart';

/// Pantalla LV1 (rodada en vivo). `sharing` es la máquina de estados del
/// tracking propio; `riders` es la lista en vivo de todos los
/// participantes (Realtime); `myPosition` alimenta el marcador propio del
/// mapa mientras `sharing == sharing`.
@freezed
abstract class LiveRideState with _$LiveRideState {
  const factory LiveRideState({
    @Default(ResultState<List<LiveRider>>.initial())
    ResultState<List<LiveRider>> riders,
    @Default(SharingStatus.notSharing) SharingStatus sharing,
    @Default(LocationPermissionState.denied) LocationPermissionState permission,
    @Default(false) bool isEventFinished,
    RiderPosition? myPosition,
    LiveRideContacts? contacts,
  }) = _LiveRideState;
}
