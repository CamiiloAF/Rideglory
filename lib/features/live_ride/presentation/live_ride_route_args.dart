/// `extra` de las rutas de `live_ride`: el detalle de evento (EV2) ya tiene
/// esta información cargada y evita que LV1/LV6 tengan que volver a
/// pedirla. Si la pantalla se abre desde un push (deep link, sin `extra`),
/// se usan los valores por defecto — ver pendiente en el informe de la
/// corrida.
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
}
