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

/// Fusiona los inscritos aprobados con `live_riders`, por `userId`.
List<LiveRiderRow> mergeLiveRiderRows({
  required List<EventRegistrant> registrants,
  required List<LiveRider> liveRiders,
  required String ownerId,
}) {
  final liveByUserId = {for (final rider in liveRiders) rider.userId: rider};
  return [
    for (final registrant in registrants)
      LiveRiderRow(
        userId: registrant.userId,
        fullName: registrant.fullName,
        isLeader: registrant.userId == ownerId,
        phone: registrant.phone,
        liveRider: liveByUserId[registrant.userId],
      ),
  ];
}
