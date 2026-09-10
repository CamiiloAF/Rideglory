import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/live_ride_contacts.dart';
import '../../domain/live_rider.dart';
import '../../domain/location_permission_state.dart';
import '../../domain/rider_position.dart';
import '../live_ride_route_args.dart';
import 'sharing_status.dart';

part 'live_ride_state.freezed.dart';

/// Pantalla LV1 (rodada en vivo). `sharing` es la máquina de estados del
/// tracking propio; `riders` es la lista en vivo de todos los
/// participantes (Realtime); `myPosition` alimenta el marcador propio del
/// mapa mientras `sharing == sharing`. `args` es la fuente única de verdad
/// de `LiveRideRouteArgs` para toda la sesión (`LiveRideSessionScope`):
/// empieza en `LiveRideRouteArgs.empty` cuando la pantalla se abre sin
/// `extra` (deep link de push de SOS) y `resolveArgs` la completa contra
/// `GetEventDetailUseCase`.
@freezed
abstract class LiveRideState with _$LiveRideState {
  const factory LiveRideState({
    @Default(ResultState<List<LiveRider>>.initial())
    ResultState<List<LiveRider>> riders,
    @Default(SharingStatus.notSharing) SharingStatus sharing,
    @Default(LocationPermissionState.denied) LocationPermissionState permission,
    @Default(false) bool isEventFinished,
    @Default(LiveRideRouteArgs.empty) LiveRideRouteArgs args,
    RiderPosition? myPosition,
    LiveRideContacts? contacts,
  }) = _LiveRideState;
}
