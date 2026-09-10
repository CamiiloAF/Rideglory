import 'package:dartz/dartz.dart';

import '../../../core/exceptions/domain_exception.dart';
import 'live_ride_contacts.dart';
import 'live_rider.dart';
import 'rider_position.dart';

abstract class LiveRideRepository {
  /// Última posición conocida de cada rider de la rodada, actualizada por
  /// Realtime sobre `live_positions` (D15). Un error de conexión o de
  /// servidor se emite como `Left` sin cerrar el stream.
  Stream<Either<DomainException, List<LiveRider>>> watchRiders(String eventId);

  Future<Either<DomainException, Unit>> upsertPosition(
    String eventId,
    RiderPosition position,
  );

  /// D22: para el tracking del rider actual y borra su fila de
  /// `live_positions`. Nunca toca un SOS.
  Future<Either<DomainException, Unit>> endRide(String eventId);

  Future<Either<DomainException, LiveRideContacts>> getContacts(String eventId);

  /// Señal de "el evento terminó" (D22), vista por Realtime sobre `events`.
  /// No usa `Either`: es un disparador de efectos (parar el servicio en
  /// segundo plano), no un resultado que la UI deba mostrar como error.
  Stream<bool> watchEventFinished(String eventId);
}
