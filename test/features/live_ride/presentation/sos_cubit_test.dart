import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/live_ride/domain/rider_position.dart';
import 'package:rideglory/features/live_ride/domain/sos_alert.dart';
import 'package:rideglory/features/live_ride/domain/sos_outbox.dart';
import 'package:rideglory/features/live_ride/domain/sos_outbox_item.dart';
import 'package:rideglory/features/live_ride/domain/sos_status.dart';
import 'package:rideglory/features/live_ride/domain/usecases/close_sos_use_case.dart';
import 'package:rideglory/features/live_ride/domain/usecases/raise_sos_use_case.dart';
import 'package:rideglory/features/live_ride/domain/usecases/retry_sos_outbox_use_case.dart';
import 'package:rideglory/features/live_ride/domain/usecases/watch_sos_alerts_use_case.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/sos_cubit.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/sos_send_state.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/sos_state.dart';

class _MockRaiseSos extends Mock implements RaiseSosUseCase {}

class _MockCloseSos extends Mock implements CloseSosUseCase {}

class _MockWatchAlerts extends Mock implements WatchSosAlertsUseCase {}

class _MockRetryOutbox extends Mock implements RetrySosOutboxUseCase {}

class _MockSosOutbox extends Mock implements SosOutbox {}

SosOutboxItem _pendingItem() {
  return SosOutboxItem(
    clientId: 'client-1',
    eventId: 'event-1',
    position: RiderPosition(
      lat: 4.6,
      lng: -74.1,
      recordedAt: DateTime.utc(2026, 9, 10, 12),
    ),
    createdAt: DateTime.utc(2026, 9, 10, 12),
  );
}

SosAlert _alert({SosStatus status = SosStatus.active}) {
  return SosAlert(
    id: 'sos-1',
    eventId: 'event-1',
    userId: 'user-1',
    riderName: 'Camilo',
    lat: 4.6,
    lng: -74.1,
    status: status,
    createdAt: DateTime.utc(2026, 9, 10, 12),
  );
}

void main() {
  late _MockRaiseSos raiseSos;
  late _MockCloseSos closeSos;
  late _MockWatchAlerts watchAlerts;
  late _MockRetryOutbox retryOutbox;
  late _MockSosOutbox outbox;

  setUp(() {
    raiseSos = _MockRaiseSos();
    closeSos = _MockCloseSos();
    watchAlerts = _MockWatchAlerts();
    retryOutbox = _MockRetryOutbox();
    outbox = _MockSosOutbox();
    when(() => outbox.pending()).thenAnswer((_) async => []);
    when(() => watchAlerts(any())).thenAnswer((_) => const Stream.empty());
  });

  SosCubit buildCubit() =>
      SosCubit(raiseSos, closeSos, watchAlerts, retryOutbox, outbox);

  blocTest<SosCubit, SosState>(
    'load con un SOS pendiente en la cola arranca en pending, nunca en confirmed sin red',
    build: () {
      when(() => outbox.pending()).thenAnswer((_) async => [_pendingItem()]);
      return buildCubit();
    },
    act: (cubit) => cubit.load('event-1'),
    verify: (cubit) {
      expect(cubit.state.mine, isA<SosSendPending>());
    },
  );

  blocTest<SosCubit, SosState>(
    'raise exitoso emite sending y luego confirmed',
    build: () {
      when(
        () => raiseSos.call(
          eventId: any(named: 'eventId'),
          message: any(named: 'message'),
        ),
      ).thenAnswer((_) async => Right(_alert()));
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.load('event-1');
      await cubit.raise(message: 'me caí');
    },
    verify: (cubit) {
      expect(cubit.state.mine, isA<SosSendConfirmed>());
    },
  );

  blocTest<SosCubit, SosState>(
    'raise sin red emite pending, nunca confirmed (la UI nunca dice enviado sin confirmación)',
    build: () {
      when(
        () => raiseSos.call(
          eventId: any(named: 'eventId'),
          message: any(named: 'message'),
        ),
      ).thenAnswer((_) async => Left(_pendingItem()));
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.load('event-1');
      await cubit.raise();
    },
    verify: (cubit) {
      expect(cubit.state.mine, isA<SosSendPending>());
    },
  );

  blocTest<SosCubit, SosState>(
    'others se llena con las alertas de watchAlerts',
    build: () {
      when(
        () => watchAlerts(any()),
      ).thenAnswer((_) => Stream.value(Right([_alert()])));
      return buildCubit();
    },
    act: (cubit) => cubit.load('event-1'),
    wait: const Duration(milliseconds: 10),
    verify: (cubit) {
      expect(cubit.state.others, isA<Data<List<SosAlert>>>());
    },
  );

  blocTest<SosCubit, SosState>(
    'closeMine llama al caso de uso y refleja el cierre confirmado',
    build: () {
      when(
        () => raiseSos.call(
          eventId: any(named: 'eventId'),
          message: any(named: 'message'),
        ),
      ).thenAnswer((_) async => Right(_alert()));
      when(
        () => closeSos.call(any()),
      ).thenAnswer((_) async => Right(_alert(status: SosStatus.closed)));
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.load('event-1');
      await cubit.raise();
      await cubit.closeMine();
    },
    verify: (cubit) {
      expect(cubit.state.mine, isA<SosSendClosed>());
      verify(() => closeSos.call('sos-1')).called(1);
    },
  );
}
