import '../../events/domain/event_registrant.dart';
import '../domain/live_rider.dart';

/// Una fila de LV6 (riders del organizador): el registro del inscrito
/// (nombre, teléfono) fusionado con su última posición en vivo, si está
/// compartiendo. `liveRider == null` es "No comparte su ubicación", no un
/// error — D20: nunca una alarma, solo información.
class LiveRiderRow {
  const LiveRiderRow({
    required this.userId,
    required this.fullName,
    required this.isLeader,
    this.phone,
    this.liveRider,
  });

  final String userId;
  final String fullName;
  final bool isLeader;
  final String? phone;
  final LiveRider? liveRider;

  bool get isSharing => liveRider != null;
}

/// Fusiona los inscritos aprobados con `live_riders`, por `userId`. El
/// organizador nunca se inscribe a su propia rodada, así que no aparece en
/// `registrants` — cuando el viewer es un participante aprobado (no el
/// propio organizador), `organizerName`/`organizerPhone` (de
/// `get_live_ride_contacts`, ya cacheados en `LiveRideState.contacts`)
/// completan su fila como líder aunque no figure en `event_registrations`.
/// Cuando el viewer es el organizador, no se pasan (no necesita su propio
/// teléfono).
List<LiveRiderRow> mergeLiveRiderRows({
  required List<EventRegistrant> registrants,
  required List<LiveRider> liveRiders,
  required String ownerId,
  String? organizerName,
  String? organizerPhone,
}) {
  final liveByUserId = {for (final rider in liveRiders) rider.userId: rider};
  final rows = [
    for (final registrant in registrants)
      LiveRiderRow(
        userId: registrant.userId,
        fullName: registrant.fullName,
        isLeader: registrant.userId == ownerId,
        phone: registrant.phone,
        liveRider: liveByUserId[registrant.userId],
      ),
  ];
  final hasOrganizerRow = rows.any((row) => row.userId == ownerId);
  if (!hasOrganizerRow && organizerName != null && ownerId.isNotEmpty) {
    rows.insert(
      0,
      LiveRiderRow(
        userId: ownerId,
        fullName: organizerName,
        isLeader: true,
        phone: organizerPhone,
        liveRider: liveByUserId[ownerId],
      ),
    );
  }
  return rows;
}
