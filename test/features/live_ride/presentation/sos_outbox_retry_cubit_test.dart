import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/features/live_ride/domain/usecases/retry_sos_outbox_use_case.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/sos_outbox_retry_cubit.dart';
import 'package:rideglory/shared/cubits/connectivity/connectivity_cubit.dart';
import 'package:rideglory/shared/cubits/connectivity/connectivity_state.dart';

class _MockRetryOutbox extends Mock implements RetrySosOutboxUseCase {}

class _MockConnectivityCubit extends Mock implements ConnectivityCubit {}

void main() {
  late _MockRetryOutbox retryOutbox;
  late _MockConnectivityCubit connectivity;

  setUp(() {
    retryOutbox = _MockRetryOutbox();
    connectivity = _MockConnectivityCubit();
    when(() => retryOutbox.call()).thenAnswer((_) async => []);
    when(() => connectivity.stream).thenAnswer((_) => const Stream.empty());
  });

  test(
    'reintenta la cola al arrancar, sin esperar señal ni el heartbeat',
    () async {
      final cubit = SosOutboxRetryCubit(connectivity, retryOutbox);
      await Future<void>.delayed(Duration.zero);

      verify(() => retryOutbox.call()).called(1);
      await cubit.close();
    },
  );

  test('reintenta con un latido periódico aunque nunca haya una transición '
      'de conectividad — una señal débil suele fallar petición por '
      'petición sin que el sistema reporte "sin conexión" en ningún '
      'momento (D16)', () async {
    fakeAsync((async) {
      final cubit = SosOutboxRetryCubit(connectivity, retryOutbox);
      async.elapse(Duration.zero); // el intento de arranque

      async.elapse(SosOutboxRetryCubit.heartbeatInterval);
      async.elapse(SosOutboxRetryCubit.heartbeatInterval);

      verify(() => retryOutbox.call()).called(3); // arranque + 2 latidos
      unawaited(cubit.close());
    });
  });

  test('reintenta al recuperar conectividad', () async {
    when(
      () => connectivity.stream,
    ).thenAnswer((_) => Stream.value(const ConnectivityState.online()));
    final cubit = SosOutboxRetryCubit(connectivity, retryOutbox);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    verify(() => retryOutbox.call()).called(greaterThanOrEqualTo(2));
    await cubit.close();
  });
}
