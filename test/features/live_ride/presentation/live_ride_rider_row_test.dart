import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/features/events/domain/event_registrant.dart';
import 'package:rideglory/features/events/domain/registration_status.dart';
import 'package:rideglory/features/live_ride/presentation/live_ride_rider_row.dart';

/// LV6, D17: el organizador nunca se inscribe a su propia rodada, así que
/// `mergeLiveRiderRows` lo agrega como líder desde `get_live_ride_contacts`
/// cuando el viewer es un participante y no aparece en `registrants`.
void main() {
  const registrant = EventRegistrant(
    id: 'reg-2',
    userId: 'user-2',
    fullName: 'Camilo Agudelo',
    status: RegistrationStatus.approved,
    shareMedicalInfo: false,
    allowOrganizerContact: true,
    phone: '+573002223344',
  );

  test('agrega al organizador como líder cuando no está en registrants y hay '
      'nombre cacheado', () {
    final rows = mergeLiveRiderRows(
      registrants: [registrant],
      liveRiders: const [],
      ownerId: 'owner-1',
      organizerName: 'Juan Camilo',
      organizerPhone: '+573001110000',
    );

    expect(rows, hasLength(2));
    final organizerRow = rows.firstWhere((row) => row.userId == 'owner-1');
    expect(organizerRow.isLeader, isTrue);
    expect(organizerRow.fullName, 'Juan Camilo');
    expect(organizerRow.phone, '+573001110000');
  });

  test('no agrega al organizador si ya está en registrants', () {
    const organizerRegistrant = EventRegistrant(
      id: 'owner-1',
      userId: 'owner-1',
      fullName: 'Juan Camilo',
      status: RegistrationStatus.approved,
      shareMedicalInfo: false,
      allowOrganizerContact: true,
      phone: '+573001110000',
    );

    final rows = mergeLiveRiderRows(
      registrants: [organizerRegistrant, registrant],
      liveRiders: const [],
      ownerId: 'owner-1',
      organizerName: 'Ignorado',
      organizerPhone: '+573009998877',
    );

    expect(rows, hasLength(2));
    final organizerRow = rows.firstWhere((row) => row.userId == 'owner-1');
    expect(organizerRow.fullName, 'Juan Camilo');
    expect(organizerRow.phone, '+573001110000');
  });

  test('no agrega nada sintético cuando el viewer es el organizador (sin '
      'organizerName)', () {
    final rows = mergeLiveRiderRows(
      registrants: [registrant],
      liveRiders: const [],
      ownerId: 'owner-1',
    );

    expect(rows, hasLength(1));
    expect(rows.any((row) => row.userId == 'owner-1'), isFalse);
  });
}
