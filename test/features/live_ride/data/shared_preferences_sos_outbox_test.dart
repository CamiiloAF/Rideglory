import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/features/live_ride/data/services/shared_preferences_sos_outbox.dart';
import 'package:rideglory/features/live_ride/domain/rider_position.dart';
import 'package:rideglory/features/live_ride/domain/sos_outbox_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

SosOutboxItem _item(String clientId, {String eventId = 'event-1'}) {
  return SosOutboxItem(
    clientId: clientId,
    eventId: eventId,
    position: RiderPosition(
      lat: 4.6,
      lng: -74.1,
      recordedAt: DateTime.utc(2026, 9, 10, 12),
    ),
    createdAt: DateTime.utc(2026, 9, 10, 12),
  );
}

void main() {
  late SharedPreferencesSosOutbox outbox;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    outbox = SharedPreferencesSosOutbox(prefs);
  });

  test('enqueue persiste el item y pending lo devuelve', () async {
    await outbox.enqueue(_item('client-1'));

    final pending = await outbox.pending();

    expect(pending, hasLength(1));
    expect(pending.single.clientId, 'client-1');
    expect(pending.single.attempts, 0);
  });

  test('enqueue es idempotente por clientId', () async {
    await outbox.enqueue(_item('client-1'));
    await outbox.enqueue(_item('client-1'));

    final pending = await outbox.pending();

    expect(pending, hasLength(1));
  });

  test('markSent elimina el item de la cola', () async {
    await outbox.enqueue(_item('client-1'));

    await outbox.markSent('client-1');

    expect(await outbox.pending(), isEmpty);
  });

  test('markAttempt incrementa el contador sin sacar el item de la cola', () async {
    await outbox.enqueue(_item('client-1'));

    await outbox.markAttempt('client-1');
    await outbox.markAttempt('client-1');

    final pending = await outbox.pending();
    expect(pending, hasLength(1));
    expect(pending.single.attempts, 2);
  });

  test('sobrevive a una nueva instancia leyendo el mismo SharedPreferences', () async {
    await outbox.enqueue(_item('client-1'));

    final prefs = await SharedPreferences.getInstance();
    final reloaded = SharedPreferencesSosOutbox(prefs);

    final pending = await reloaded.pending();
    expect(pending, hasLength(1));
  });
}
