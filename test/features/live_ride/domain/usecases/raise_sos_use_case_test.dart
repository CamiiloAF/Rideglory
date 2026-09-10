import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/live_ride/domain/battery_service.dart';
import 'package:rideglory/features/live_ride/domain/location_service.dart';
import 'package:rideglory/features/live_ride/domain/rider_position.dart';
import 'package:rideglory/features/live_ride/domain/sos_alert.dart';
import 'package:rideglory/features/live_ride/domain/sos_outbox.dart';
import 'package:rideglory/features/live_ride/domain/sos_outbox_item.dart';
import 'package:rideglory/features/live_ride/domain/sos_repository.dart';
import 'package:rideglory/features/live_ride/domain/sos_status.dart';
import 'package:rideglory/features/live_ride/domain/usecases/raise_sos_use_case.dart';

class _MockLocationService extends Mock implements LocationService {}

class _MockBatteryService extends Mock implements BatteryService {}

class _MockSosOutbox extends Mock implements SosOutbox {}

class _MockSosRepository extends Mock implements SosRepository {}

class _FakeSosOutboxItem extends Fake implements SosOutboxItem {}

void main() {
  late _MockLocationService locationService;
  late _MockBatteryService batteryService;
  late _MockSosOutbox outbox;
  late _MockSosRepository repository;
  late RaiseSosUseCase useCase;

  final position = RiderPosition(
    lat: 4.6,
    lng: -74.1,
    recordedAt: DateTime.utc(2026, 9, 10, 12),
  );

  setUpAll(() {
    registerFallbackValue(_FakeSosOutboxItem());
    registerFallbackValue(const Duration(seconds: 5));
  });

  setUp(() {
    locationService = _MockLocationService();
    batteryService = _MockBatteryService();
    outbox = _MockSosOutbox();
    repository = _MockSosRepository();
    useCase = RaiseSosUseCase(
      locationService,
      batteryService,
      outbox,
      repository,
    );

    when(
      () => locationService.currentPosition(timeout: any(named: 'timeout')),
    ).thenAnswer((_) async => position);
    when(() => batteryService.currentLevel()).thenAnswer((_) async => 80);
    when(() => outbox.enqueue(any())).thenAnswer((_) async {});
    when(() => outbox.markSent(any())).thenAnswer((_) async {});
    when(() => outbox.markAttempt(any())).thenAnswer((_) async {});
  });

  test('encola el item ANTES de intentar la red', () async {
    final callOrder = <String>[];
    when(() => outbox.enqueue(any())).thenAnswer((_) async {
      callOrder.add('enqueue');
    });
    when(() => repository.raise(any())).thenAnswer((_) async {
      callOrder.add('raise');
      return const Left(DomainException(message: 'offline'));
    });

    await useCase.call(eventId: 'event-1');

    expect(callOrder, ['enqueue', 'raise']);
  });

  test(
    'con red caída devuelve Left con el item pendiente y lo deja en cola',
    () async {
      when(() => repository.raise(any())).thenAnswer(
        (_) async => const Left(DomainException(message: 'offline')),
      );

      final result = await useCase.call(eventId: 'event-1', message: 'me caí');

      expect(result.isLeft(), isTrue);
      result.fold((item) {
        expect(item.eventId, 'event-1');
        expect(item.message, 'me caí');
        expect(item.position.lat, position.lat);
        expect(item.position.lng, position.lng);
        expect(item.position.batteryPct, 80);
      }, (_) => fail('esperaba Left'));
      verify(() => outbox.markAttempt(any())).called(1);
      verifyNever(() => outbox.markSent(any()));
    },
  );

  test('con éxito marca enviado y devuelve la alerta confirmada', () async {
    final alert = SosAlert(
      id: 'sos-1',
      eventId: 'event-1',
      userId: 'user-1',
      riderName: 'Camilo',
      lat: 4.6,
      lng: -74.1,
      status: SosStatus.active,
      createdAt: DateTime.utc(2026, 9, 10, 12),
    );
    when(() => repository.raise(any())).thenAnswer((_) async => Right(alert));

    final result = await useCase.call(eventId: 'event-1');

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('esperaba Right'), (confirmed) {
      expect(confirmed.id, 'sos-1');
    });
    verify(() => outbox.markSent(any())).called(1);
    verifyNever(() => outbox.markAttempt(any()));
  });

  test(
    'dos llamadas generan clientId distintos (idempotencia por clientId real)',
    () async {
      when(() => repository.raise(any())).thenAnswer(
        (_) async => const Left(DomainException(message: 'offline')),
      );

      final captured = <String>[];
      when(() => outbox.enqueue(any())).thenAnswer((invocation) async {
        final item = invocation.positionalArguments.first as SosOutboxItem;
        captured.add(item.clientId);
      });

      await useCase.call(eventId: 'event-1');
      await useCase.call(eventId: 'event-1');

      expect(captured.toSet(), hasLength(2));
    },
  );
}
