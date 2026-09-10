/// `extra` de las rutas de `live_ride`: el detalle de evento (EV2) ya tiene
/// esta información cargada y evita que LV1/LV6 tengan que volver a
/// pedirla. Si la pantalla se abre desde un push de SOS (deep link, sin
/// `extra`), llega [empty] y `LiveRideCubit.resolveArgs` la completa contra
/// `GetEventDetailUseCase`.
class LiveRideRouteArgs {
  const LiveRideRouteArgs({
    required this.eventName,
    required this.isOwner,
    required this.ownerId,
  });

  final String eventName;
  final bool isOwner;
  final String ownerId;

  static const empty = LiveRideRouteArgs(
    eventName: '',
    isOwner: false,
    ownerId: '',
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LiveRideRouteArgs &&
          other.eventName == eventName &&
          other.isOwner == isOwner &&
          other.ownerId == ownerId);

  @override
  int get hashCode => Object.hash(eventName, isOwner, ownerId);
}
