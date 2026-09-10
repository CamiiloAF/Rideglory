import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/live_ride/domain/rider_position.dart';
import 'package:rideglory/features/live_ride/domain/sos_alert.dart';
import 'package:rideglory/features/live_ride/domain/sos_outbox.dart';
import 'package:rideglory/features/live_ride/domain/sos_outbox_item.dart';
import 'package:rideglory/features/live_ride/domain/sos_repository.dart';
import 'package:rideglory/features/live_ride/domain/sos_status.dart';
import 'package:rideglory/features/live_ride/domain/usecases/retry_sos_outbox_use_case.dart';

class _MockSosOutbox extends Mock implements SosOutbox {}

class _MockSosRepository extends Mock implements SosRepository {}

class _FakeSosOutboxItem extends Fake implements SosOutboxItem {}

SosOutboxItem _item(String clientId, String eventId) {
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

SosAlert _alert(String id, String eventId) {
  return SosAlert(
    id: id,
    eventId: eventId,
    userId: 'user-1',
    riderName: 'Camilo',
    lat: 4.6,
    lng: -74.1,
    status: SosStatus.active,
    createdAt: DateTime.utc(2026, 9, 10, 12),
  );
}

void main() {
  late _MockSosOutbox outbox;
  late _MockSosRepository repository;
  late RetrySosOutboxUseCase useCase;

  setUpAll(() {
    registerFallbackValue(_FakeSosOutboxItem());
  });

  setUp(() {
    outbox = _MockSosOutbox();
    repository = _MockSosRepository();
    useCase = RetrySosOutboxUseCase(outbox, repository);
    when(() => outbox.markSent(any())).thenAnswer((_) async {});
    when(() => outbox.markAttempt(any())).thenAnswer((_) async {});
  });

  test('reintenta cada item pendiente y devuelve las alertas confirmadas', () async {
    when(() => outbox.pending())
        .thenAnswer((_) async => [_item('c1', 'e1'), _item('c2', 'e1')]);
    when(() => repository.raise(any())).thenAnswer(
      (invocation) async {
        final item = invocation.positionalArguments.first as SosOutboxItem;
        return Right(_alert('sos-${item.clientId}', item.eventId));
      },
    );

    final confirmed = await useCase.call();

    expect(confirmed, hasLength(2));
    verify(() => outbox.markSent('c1')).called(1);
    verify(() => outbox.markSent('c2')).called(1);
  });

  test('un item que sigue fallando queda en cola (markAttempt) y no se reporta confirmado', () async {
    when(() => outbox.pending()).thenAnswer((_) async => [_item('c1', 'e1')]);
    when(() => repository.raise(any())).thenAnswer(
      (_) async => const Left(DomainException(message: 'offline')),
    );

    final confirmed = await useCase.call();

    expect(confirmed, isEmpty);
    verify(() => outbox.markAttempt('c1')).called(1);
    verifyNever(() => outbox.markSent(any()));
  });

  test('cola vacía no llama a raise', () async {
    when(() => outbox.pending()).thenAnswer((_) async => []);

    final confirmed = await useCase.call();

    expect(confirmed, isEmpty);
    verifyNever(() => repository.raise(any()));
  });
}
